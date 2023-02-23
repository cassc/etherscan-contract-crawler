// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./OwnableUpgradeable.sol";
interface ERC721 {
    function mint(address to, uint256 tokenId, string memory _uri, string memory _payload) external;
    function transferOwnership(address newOwner) external;
}

contract BulkMinter is OwnableUpgradeable {

    function initialize() public initializer {
        __Ownable_init();
    }
    
    function bulkMint(address _contract, address[] memory _to, uint256[] memory _tokenId) public onlyOwner {
        require(_to.length == _tokenId.length, "Arrays must have the same length");
        
        for (uint256 i = 0; i < _to.length; i++) { 
            string memory uri = string(abi.encodePacked("https://api.emblemvault.io/s:evmetadata/meta/", uint2str(_tokenId[i])));
            ERC721(_contract).mint(_to[i], _tokenId[i], uri, '');
        }
    }
    
    function transferContractOwnership(address _contract, address _newOwner) public onlyOwner {
        ERC721(_contract).transferOwnership(_newOwner);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}