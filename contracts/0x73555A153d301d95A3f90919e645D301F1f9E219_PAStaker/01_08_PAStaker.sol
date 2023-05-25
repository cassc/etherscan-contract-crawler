// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Delegated } from "./Delegated.sol";

contract PAStaker is IERC721Receiver, Delegated {
    using EnumerableSet for EnumerableSet.UintSet;

    IERC721 public immutable GENESIS;     // 0x75E95ba5997Eb235F40eCF8347cDb11F18ff640B
    IERC721 public immutable COMPONENT_1; // 0x5501024dDb740266Fa0d69d19809EC86dB5E3f8b
    IERC721 public immutable PSILOCYBIN;  // 0x11ca9693156929EE2e7E1470C5E1A55b413e9007
    IERC721[3] public TOKEN_CONTRACTS;

    constructor(address _genesis, address _component1, address _psilocybin) {
        GENESIS = IERC721(_genesis);
        COMPONENT_1 = IERC721(_component1);
        PSILOCYBIN = IERC721(_psilocybin);

        TOKEN_CONTRACTS = [ GENESIS, COMPONENT_1, PSILOCYBIN ];
    }

    enum TokenType { Genesis, Component1, Psilocybin }
    struct TokenInfo { address owner; uint256 timeStaked; }
    mapping(TokenType => mapping(uint256 => TokenInfo)) public tokenInfo;
    mapping(address => mapping(TokenType => EnumerableSet.UintSet)) stakedTokens;

    /*
     * VIEW FUNCTIONS
     */
    function timeSinceStaked(TokenType _tokenType, uint256 _id) public view returns (uint256) {
        uint timeStaked = tokenInfo[_tokenType][_id].timeStaked;
        return timeStaked == 0 ? 0 : block.timestamp - timeStaked;
    }

    function batchTimeSinceStaked(TokenType _tokenType, uint256[] calldata _ids) external view returns (uint256[] memory) {
        uint256 _length = _ids.length;
        uint256[] memory timeStamps = new uint256[](_length);
        for(uint i = 0; i < _length;) {
            timeStamps[i] = timeSinceStaked(_tokenType, _ids[i]);
            unchecked { i++; }
        }
        return timeStamps;
    }

    function isStaked(address _owner, TokenType _tokenType, uint256 _id) external view returns (bool) {
        return stakedTokens[_owner][_tokenType].contains(_id);
    }

    function stakedBalance(address _owner, TokenType _tokenType) external view returns (uint256) {
        return stakedTokens[_owner][_tokenType].length();
    }

    function getStakedTokens(address _owner, TokenType _tokenType) external view returns (uint256[] memory) {
        return stakedTokens[_owner][_tokenType].values();
    }

    /*
     * USER FUNCTIONS
     */
     /** @dev batchStake requires setApprovalForAll before using */
    function batchStake(uint256[] calldata _ids, TokenType _tokenType) external {
        for(uint i = 0; i < _ids.length; ) {
            TokenInfo storage _token = tokenInfo[_tokenType][_ids[i]];
            _token.owner = msg.sender;
            _token.timeStaked = block.timestamp;

            require(stakedTokens[msg.sender][_tokenType].add(_ids[i]), "STAKER: token already staked");
            _contractTransfer(msg.sender, address(this), _ids[i], uint256(_tokenType));
            unchecked { i++; }
        }
    }

    function unstake(uint256 _id, TokenType _tokenType) public {
        address _owner = tokenInfo[_tokenType][_id].owner;
        require(msg.sender == _owner, "not owner");

        delete tokenInfo[_tokenType][_id];
        require(stakedTokens[msg.sender][_tokenType].remove(_id), "STAKER: staked token not found");
        _contractSafeTransfer(address(this), _owner, _id, uint(_tokenType));
    }

    function batchUnstake(uint256[] calldata _ids, TokenType _tokenType) external {
        for(uint i = 0; i < _ids.length; ) {
            unstake(_ids[i], _tokenType);
            unchecked { i++; }
        }
    }

    /*
     * ONLY DELEGATES
     */
     /** @dev this function can only be used by specific addresses to unstake tokens and return them back to their owner */
    function delegatedUnstake(uint256 _id, TokenType _tokenType) public onlyDelegates {
        address _owner = tokenInfo[_tokenType][_id].owner;

        delete tokenInfo[_tokenType][_id];
        require(stakedTokens[_owner][_tokenType].remove(_id), "STAKER: staked token not found");
        _contractSafeTransfer(address(this), _owner, _id, uint(_tokenType));
    }

    function delegatedBatchUnstake(uint256[] calldata _ids, TokenType _tokenType) external {
        for(uint i = 0; i < _ids.length; ) {
            delegatedUnstake(_ids[i], _tokenType);
            unchecked { i++; }
        }
    }

    /*
     * PRIVATE FUNCTIONS
     */
     function _contractTransfer(address _from, address _to, uint256 _id, uint256 _contractIndex) private {
        require(_contractIndex < 3, "invalid contract type");
        TOKEN_CONTRACTS[_contractIndex].transferFrom(_from, _to, _id);
    }

     function _contractSafeTransfer(address _from, address _to, uint256 _id, uint256 _contractIndex) private {
        require(_contractIndex < 3, "invalid contract type");
        TOKEN_CONTRACTS[_contractIndex].safeTransferFrom(_from, _to, _id);
    }

    function _getContractType(address _contract) private view returns (TokenType) {
        if (_contract == address(GENESIS)) return TokenType.Genesis;
        if (_contract == address(COMPONENT_1)) return TokenType.Component1;
        if (_contract == address(PSILOCYBIN)) return TokenType.Psilocybin;
        revert("wrong token received");
    }

    /*
     * OVERRIDES
     */
     /** @dev this will only be called if a token uses safeTransferFrom to send to this contract. transferFrom will not trigger this */
    function onERC721Received(
        address, // unused
        address _from,
        uint256 _id,
        bytes memory // unused
    ) public override returns (bytes4) {
        TokenType _contractType = _getContractType(msg.sender);

        TokenInfo storage _token = tokenInfo[_contractType][_id];
        _token.owner = _from;
        _token.timeStaked = block.timestamp;

        require(stakedTokens[_from][_contractType].add(_id), "STAKER: already staked");
        return this.onERC721Received.selector;
    }
}

/***************************************
 * @author: 🍖                         *
 * @team:   Asteria                     *
 ****************************************/