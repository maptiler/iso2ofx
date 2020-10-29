import { colonSymbolCode } from '../tokens.js';
import bufferToText from '../utils/buffer-to-text.js';
import compareArrays from '../utils/compare-arrays.js';
/**
 * @description :20:
 * @type {Uint8Array}
 */
var token = new Uint8Array([colonSymbolCode, 50, 48, colonSymbolCode]);
var tokenLength = token.length;
var transactionReferenceNumberTag = {
    readToken: function (state) {
        if (!compareArrays(token, 0, state.data, state.pos, tokenLength)) {
            return 0;
        }
        return state.pos + tokenLength;
    },
    open: function (state) {
        state.statementIndex++;
        state.transactionIndex = -1;
        state.statements.push({
            transactions: []
        });
    },
    close: function (state) {
        var statement = state.statements[state.statementIndex];
        if (!statement) {
            return;
        }
        statement.referenceNumber = bufferToText(state.data, state.tagContentStart, state.tagContentEnd);
    }
};
export default transactionReferenceNumberTag;
