// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "@0xver/solver/supports/ERC721Supports.sol";
import "./IPSYCHOLimitedErrors.sol";

contract PSYCHOSetup is IPSCYHOLimitedErrors, ERC721Supports {
    error InitiateStatusIs(bool _status);

    bool private _initiated = false;
    bool private _locked = false;

    uint256 private _weiFee = 200000000000000000;

    mapping(uint256 => uint256) private _block;

    event Withdraw(address operator, address receiver, uint256 value);

    constructor() ERC721Metadata("PSYCHO Limited", "PSYCHO") Owner(msg.sender) {
        _setDefaultExtension(
            '"image":"ipfs://bafybeidob7iaynjg6h6c3igqnac2qnprlzsfatybuqkxhcizcgpfowwgm4","animation_url":"ipfs://bafybeihmygiurvygn7oaruaz66njkvlicbfg7lnsc64ttxbc3o3x4fezfi"'
        );
        _mint(msg.sender, 1);
    }

    receive() external payable {}

    fallback() external payable {}

    function withdraw(address _to) public ownership {
        _withdraw(_to);
    }

    function initialize() public ownership {
        if (_initiated == false) {
            _initiated = true;
        } else {
            revert InitiateStatusIs(_initiated);
        }
    }

    function setFee(uint256 _wei) public ownership {
        _weiFee = _wei;
    }

    function resign(bool _bool) public ownership {
        require(_bool == true);
        _weiFee = 0;
        _withdraw(msg.sender);
        _transferOwnership(address(0));
        _locked = true;
    }

    function resigned() public view returns (bool) {
        return _locked;
    }

    function _generative() internal view returns (bool) {
        if (totalSupply() != 1101) {
            return _initiated;
        } else {
            return false;
        }
    }

    function _fee(uint256 _multiplier) internal view returns (uint256) {
        return _weiFee * _multiplier;
    }

    function _mintHook(uint256 _avatarId) internal override(ERC721) {
        _block[_avatarId] = block.number;
    }

    function _defaultExtensionTokenURI(uint256 _avatarId)
        internal
        view
        override(ERC721Metadata)
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _coreTokenURI(_avatarId),
                ",",
                _description(_avatarId),
                ",",
                _defaultExtensionString(),
                ",",
                _attributes(_avatarId)
            );
    }

    function _customExtensionTokenURI(uint256 _avatarId)
        internal
        view
        override(ERC721Metadata)
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _description(_avatarId),
                ",",
                _customExtensionString(_avatarId),
                ",",
                _attributes(_avatarId)
            );
    }

    function _description(uint256 _avatarId)
        internal
        view
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                '"description":"',
                Encode.toString(_block[_avatarId]),
                '"'
            );
    }

    function _attributes(uint256 _avatarId)
        internal
        view
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                '"attributes":[{"trait_type":"Block","value":"',
                Encode.toHexString(_block[_avatarId]),
                '"}]'
            );
    }

    function _withdraw(address _to) private {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(_to).call{value: address(this).balance}("");
        require(success, "ETH_TRANSFER_FAILED");
        emit Withdraw(msg.sender, _to, balance);
    }
}