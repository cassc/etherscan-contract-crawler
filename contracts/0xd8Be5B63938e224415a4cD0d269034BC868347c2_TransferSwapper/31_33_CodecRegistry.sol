// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICodec.sol";

/**
 * @title A codec registry that maps swap function selectors to corresponding codec addresses
 * @author Padoriku
 */
abstract contract CodecRegistry is Ownable {
    mapping(bytes4 => ICodec) public selector2codec;

    // not used programmatically, but added for contract transparency
    address[] public codecs;

    event CodecUpdated(bytes4 selector, address codec);

    constructor(string[] memory _funcSigs, address[] memory _codecs) {
        require(_funcSigs.length == _codecs.length, "len mm");
        for (uint256 i = 0; i < _funcSigs.length; i++) {
            bytes4 selector = bytes4(keccak256(bytes(_funcSigs[i])));
            _setCodec(selector, _codecs[i]);
        }
    }

    function setCodec(string calldata _funcSig, address _codec) public onlyOwner {
        bytes4 selector = bytes4(keccak256(bytes(_funcSig)));
        _setCodec(selector, _codec);
        emit CodecUpdated(selector, _codec);
    }

    function _setCodec(bytes4 _selector, address _codec) private {
        selector2codec[_selector] = ICodec(_codec);
        codecs.push(_codec);
    }

    function loadCodecs(ICodec.SwapDescription[] memory _swaps) internal view returns (ICodec[] memory) {
        ICodec[] memory _codecs = new ICodec[](_swaps.length);
        for (uint256 i = 0; i < _swaps.length; i++) {
            bytes4 selector = bytes4(_swaps[i].data);
            _codecs[i] = selector2codec[selector];
            require(address(_codecs[i]) != address(0), "cdc no found");
        }
        return (_codecs);
    }

    function getCodec(
        bytes4[] memory _selectors,
        ICodec[] memory _codecs,
        bytes4 _selector
    ) internal pure returns (ICodec) {
        for (uint256 i = 0; i < _codecs.length; i++) {
            if (_selector == _selectors[i]) {
                return _codecs[i];
            }
        }
        revert("cdc no found");
    }
}