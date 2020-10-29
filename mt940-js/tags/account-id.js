import { colonSymbolCode } from '../tokens.js';
import bufferToText from '../utils/buffer-to-text.js';
import compareArrays from '../utils/compare-arrays.js';
/**
 * @description :25:
 * @type {Uint8Array}
 */
var token = new Uint8Array([colonSymbolCode, 50, 53, colonSymbolCode]);
var tokenLength = token.length;
var accountIdTag = {
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
        statement.accountId = bufferToText(state.data, state.tagContentStart, state.tagContentEnd);
    }
};
export default accountIdTag;
