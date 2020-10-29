import { bigCSymbolCode, colonSymbolCode, dotSymbolCode } from '../tokens.js';
import bufferToText from '../utils/buffer-to-text.js';
import compareArrays from '../utils/compare-arrays.js';
var transactionInfoPattern = new RegExp([
    '^\\s*',
    '([0-9]{2})',
    '([0-9]{2})',
    '([0-9]{2})',
    '([0-9]{2})?',
    '([0-9]{2})?',
    '(C|D|RD|RC|EC|ED)',
    '([A-Z]{1})?',
    '([0-9]+[,.][0-9]*)',
    '([A-Z0-9]{4})?',
    '([^/\n\r]{0,16}|NONREF)?',
    '(//[A-Z0-9]{16})?' // Bank reference
].join(''));
var commaPattern = /,/;
var dotSymbol = String.fromCharCode(dotSymbolCode);
var incomeTransactionCodes = [
    // ABN AMRO bank
    'N653',
    'N654',
    // ING bank
    'N060'
];
/**
 * @description :61:
 * @type {Uint8Array}
 */
export var token = new Uint8Array([colonSymbolCode, 54, 49, colonSymbolCode]);
var tokenLength = token.length;
var transactionInfoTag = {
    readToken: function (state) {
        if (!compareArrays(token, 0, state.data, state.pos, tokenLength)) {
            return 0;
        }
        return state.pos + tokenLength;
    },
    open: function (state) {
        var statement = state.statements[state.statementIndex];
        if (statement) {
            var openingBalance = statement.openingBalance;
            statement.transactions.push({
                id: '',
                code: '',
                fundsCode: '',
                isCredit: false,
                isExpense: true,
                currency: openingBalance ? openingBalance.currency : '',
                description: '',
                amount: 0,
                valueDate: '',
                entryDate: '',
                customerReference: '',
                bankReference: ''
            });
        }
        state.transactionIndex++;
    },
    close: function (state, options) {
        var statement = state.statements[state.statementIndex];
        var transaction = statement && statement.transactions[state.transactionIndex];
        if (!transaction) {
            return;
        }
        var content = bufferToText(state.data, state.tagContentStart, state.tagContentEnd);
        var _a = transactionInfoPattern.exec(content) || [], valueDateYear = _a[1], valueDateMonth = _a[2], valueDate = _a[3], entryDateMonth = _a[4], entryDate = _a[5], creditMark = _a[6], fundsCode = _a[7], amount = _a[8], code = _a[9], customerReference = _a[10], bankReference = _a[11];
        if (!valueDateYear) {
            return;
        }
        var year = Number(valueDateYear) > 80 ? "19" + valueDateYear : "20" + valueDateYear;
        transaction.valueDate = year + "-" + valueDateMonth + "-" + valueDate;
        if (entryDateMonth) {
            transaction.entryDate = year + "-" + entryDateMonth + "-" + entryDate;
        }
        transaction.isCredit = creditMark
            ? creditMark.charCodeAt(0) === bigCSymbolCode || creditMark.charCodeAt(1) === bigCSymbolCode
            : false;
        if (fundsCode) {
            transaction.fundsCode = fundsCode;
        }
        if (customerReference && customerReference !== 'NONREF') {
            transaction.customerReference = customerReference;
        }
        if (bankReference && bankReference !== '//NONREF') {
            transaction.bankReference = bankReference.slice(2);
        }
        transaction.amount = parseFloat(amount.replace(commaPattern, dotSymbol));
        transaction.code = code;
        transaction.isExpense = incomeTransactionCodes.indexOf(code) === -1;
        transaction.id = options.getTransactionId(transaction, state.transactionIndex);
    }
};
export default transactionInfoTag;
