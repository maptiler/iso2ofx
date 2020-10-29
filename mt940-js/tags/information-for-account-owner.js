import { colonSymbolCode, newLineSymbolCode, returnSymbolCode, spaceSymbolCode } from '../tokens.js';
import bufferToText from '../utils/buffer-to-text.js';
import compareArrays from '../utils/compare-arrays.js';
/**
 * @description :86:
 * @type {Uint8Array}
 */
var token = new Uint8Array([colonSymbolCode, 56, 54, colonSymbolCode]);
var tokenLength = token.length;
var informationTag = {
    multiline: true,
    readToken: function (state) {
        if (!compareArrays(token, 0, state.data, state.pos, tokenLength)) {
            return 0;
        }
        return state.pos + tokenLength;
    },
    close: function (state) {
        var statement = state.statements[state.statementIndex];
        if (!statement) {
            return;
        }
        var _a = state.tagContentStart, tagContentStart = _a === void 0 ? 0 : _a, _b = state.tagContentEnd, tagContentEnd = _b === void 0 ? 0 : _b;
        var description = [];
        var descriptionLength = 0;
        // filter denied symbols
        for (var i = tagContentStart; i < tagContentEnd; i++) {
            var symbolCode = state.data[i];
            if (
            // remove \r & \n
            symbolCode !== returnSymbolCode &&
                symbolCode !== newLineSymbolCode &&
                // use 1 space instead of multiple ones
                (symbolCode !== spaceSymbolCode || description[descriptionLength - 1] !== symbolCode)) {
                description[descriptionLength] = symbolCode;
                descriptionLength++;
            }
        }
        var informationToAccountOwner = bufferToText(description).trim();
        var currentTransaction = statement.transactions[state.transactionIndex];
        // Normally, all :86: fields must be directly preceded by a transaction statement
        // line (:61:), so if the current transaction already has a description, we may
        // assume this is yet another :86: field, and therefore contains additional
        // information about the statement as a whole rather than just about the transaction.
        // Or, if no transactions at all have been encountered, and we see an :86: field, it
        // then must pertain to the account statement.
        if (currentTransaction && !currentTransaction.description) {
            currentTransaction.description = informationToAccountOwner;
        }
        else {
            statement.additionalInformation = informationToAccountOwner;
        }
    }
};
export default informationTag;
