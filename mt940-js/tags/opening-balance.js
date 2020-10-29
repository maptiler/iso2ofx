import { bigCSymbolCode, colonSymbolCode, commaSymbolCode, dotSymbolCode, nineSymbolCode } from '../tokens.js';
import bufferToText from '../utils/buffer-to-text.js';
import compareArrays from '../utils/compare-arrays.js';
/**
 * @description :60M:
 * @type {Uint8Array}
 */
var token1 = new Uint8Array([colonSymbolCode, 54, 48, 77, colonSymbolCode]);
/**
 * @description :60F:
 * @type {Uint8Array}
 */
var token2 = new Uint8Array([colonSymbolCode, 54, 48, 70, colonSymbolCode]);
var token1Length = token1.length;
var token2Length = token2.length;
var getInitialState = function () {
    return {
        info: {
            isCredit: false,
            date: '',
            currency: '',
            value: 0
        },
        contentPos: 0,
        balance: []
    };
};
var __assign = (this && this.__assign) || Object.assign || function(t) {
    for (var s, i = 1, n = arguments.length; i < n; i++) {
        s = arguments[i];
        for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
            t[p] = s[p];
    }
    return t;
};
var openingBalanceTag = __assign(__assign({}, getInitialState()), { readToken: function (state) {
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
        statement.openingBalance = this.info;
        return state.pos + (isToken1 ? token1Length : token2Length);
    },
    init: function () {
        Object.assign(this, getInitialState());
    },
    readContent: function (_state, symbolCode) {
        var _a = this, info = _a.info, contentPos = _a.contentPos;
        if (!contentPos) {
            // status is 'C'
            info.isCredit = symbolCode === bigCSymbolCode;
        }
        else if (contentPos < 7) {
            // it's a date. Collect date and convert it from YYMMDD to YYYY-MM-DD
            if (!info.date) {
                if (symbolCode === nineSymbolCode) {
                    info.date = '19';
                }
                else {
                    info.date = '20';
                }
            }
            info.date += String.fromCharCode(symbolCode);
            if (contentPos === 2 || contentPos === 4) {
                info.date += '-';
            }
        }
        else if (contentPos < 10) {
            // it's a currency
            info.currency += String.fromCharCode(symbolCode);
        }
        else {
            // it's a balance
            // use always a dot as decimal separator
            if (symbolCode === commaSymbolCode) {
                symbolCode = dotSymbolCode;
            }
            this.balance.push(symbolCode);
        }
        this.contentPos++;
    },
    close: function () {
        this.info.value = parseFloat(bufferToText(this.balance));
    } });
export default openingBalanceTag;
