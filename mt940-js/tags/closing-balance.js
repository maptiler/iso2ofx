import { colonSymbolCode } from '../tokens.js';
import compareArrays from '../utils/compare-arrays.js';
import openingBalanceTag from './opening-balance.js';
/**
 * @description :62M:
 * @type {Uint8Array}
 */
export var token1 = new Uint8Array([colonSymbolCode, 54, 50, 77, colonSymbolCode]);
/**
 * @description :62F:
 * @type {Uint8Array}
 */
export var token2 = new Uint8Array([colonSymbolCode, 54, 50, 70, colonSymbolCode]);
var token1Length = token1.length;
var token2Length = token2.length;
var __assign = (this && this.__assign) || Object.assign || function(t) {
    for (var s, i = 1, n = arguments.length; i < n; i++) {
        s = arguments[i];
        for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
            t[p] = s[p];
    }
    return t;
};
var closingBalanceTag = __assign(__assign({}, openingBalanceTag), { readToken: function (state) {
        var isToken1 = compareArrays(token1, 0, state.data, state.pos, token1Length);
        var isToken2 = !isToken1 && compareArrays(token2, 0, state.data, state.pos, token2Length);
        if (!isToken1 && !isToken2) {
            return 0;
        }
        this.init();
        var statement = state.statements[state.statementIndex];
        if (!statement) {
            return 0;
        }
        statement.closingBalance = this.info;
        return state.pos + (isToken1 ? token1Length : token2Length);
    } });
export default closingBalanceTag;
