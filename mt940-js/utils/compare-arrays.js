export default function compareArrays(firstArray, firstArrayOffset, secondArray, secondArrayOffset, length) {
    for (var i = 0; i < length; i++) {
        if (firstArray[firstArrayOffset + i] !== secondArray[secondArrayOffset + i]) {
            return false;
        }
    }
    return true;
}
