// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import "@layerzerolabs/solidity-examples/contracts/token/onft/ONFT721.sol";

contract BabyWealthyClubONFT is ONFT721 {

    string public baseTokenURI;
    uint256 public constant MAX_ELEMENTS = 10000;

    uint public totalSupply;

    constructor(string memory _name, string memory _symbol, string memory _baseTokenURI, address _lzEndpoint, uint256 _minGasToTransfer) ONFT721(_name, _symbol, _minGasToTransfer, _lzEndpoint) {
        setBaseURI(_baseTokenURI);
    }

    function _debitFrom(address _from, uint16 _t, bytes memory _d, uint _tokenId) internal virtual override(ONFT721) {
        if (totalSupply > 0) {
            totalSupply --;
        }
        ONFT721._debitFrom(_from, _t, _d, _tokenId);
    }

    function _creditTo(uint16 _t, address _toAddress, uint _tokenId) internal virtual override(ONFT721) {
        totalSupply ++;
        ONFT721._creditTo(_t, _toAddress, _tokenId);
    }

    struct ERC721Balance {
        uint total;
        uint offset;
        uint[] tokenIds;
    }

    function getERC721Balance(address _nft, address _user, uint /*_offset*/, uint /*_num*/) external view returns(ERC721Balance memory balance) {
        require(_nft == address(this), "only support this nft");
        uint userBalance = balanceOf(_user);
        balance.total = userBalance;
        uint[] memory tokenIds = new uint[](userBalance);
        uint realNum = 0;
        for (uint i = 0; i < MAX_ELEMENTS; i ++) {
            if (_ownerOf(i) == _user) {
                tokenIds[realNum ++] = i; 
                if (realNum == userBalance) {
                    break;
                }
            }
        }
        if (realNum < userBalance) {
            assembly {
                mstore(tokenIds, realNum)
            }
        }
        balance.tokenIds = tokenIds;
        return balance;
    }

    function exists(uint _tokenId) external view returns(bool) {
        return _exists(_tokenId);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

}