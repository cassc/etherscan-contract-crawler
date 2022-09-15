pragma solidity ^0.8.0;

contract BogoSort {
    uint[] private array;
    uint256 private nonce;

    constructor() {
        array = [21, 515, 123, 12, 123, 15782, 431, 6823412, 16479126, 13812];
    }

    function sort(uint256 _commitment) internal returns (bool) {
        array = bogo(array, _commitment);
        shuffle(array, _commitment);
        return true;
    }

    function bogo(uint[] memory _array, uint256 _commitment) private returns(uint[] memory) {
        while (!isSorted(_array)) {
            _array = shuffle(_array, _commitment);
        }
        return _array;
    }

    function isSorted(uint[] memory _array) private pure returns(bool) {
        for (uint i = 0; i < _array.length - 1; i++) {
            if (!(_array[i] <= _array[i+1])) {
                return false;
            }
        }
        return true;
    }

    function shuffle(uint[] memory _array, uint256 _commitment) private returns(uint[] memory) {
        for (uint i = 0; i < _array.length; i++) {
			uint nonce = random(i, _commitment);
			uint temp = _array[nonce];
			_array[nonce] = _array[i];
			_array[i] = temp;
        }
        return _array;
    }

    function random(uint256 _nonce, uint256 _commitment) private returns (uint) {
        nonce += _nonce;
        uint temp = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce, _commitment)));
        // keccak should always return a fixed lenght number so we can just do this
        while (temp >= 9) {
            temp = temp / 10;
        }
        return temp;
    }
}