import bufferToText from '../utils/buffer-to-text.js';
import compareArrays from '../utils/compare-arrays.js';
import { colonSymbolCode } from '../tokens.js';
/**
 * @description :21:
 * @type {Uint8Array}
 */
var token = new Uint8Array([colonSymbolCode, 50, 49, colonSymbolCode]);
var tokenLength = token.length;
var relatedReferenceNumberTag = {
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
        statement.relatedReferenceNumber = bufferToText(state.data, state.tagContentStart, state.tagContentEnd);
    }
};
export default relatedReferenceNumberTag;
