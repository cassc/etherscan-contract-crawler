// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @author [email protected] twitter.com/0xYuru
/// @dev aa0cdefd28cd450477ec80c28ecf3574 0x8fd31bb99658cb203b8c9034baf3f836c2bc2422fd30380fa30b8eade122618d3ca64095830cac2c0e84bc22910eef206eb43d54f71069f8d9e66cf8e4dcabec1c 
contract JukiReward is ERC1155, Pausable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    
    mapping(address => bool) private proxyContracts;
    mapping(uint256 => bool) public tokenIds;

    string private baseURI;
    string public name = "Jukiverse Scavenging Rewards";
    string public symbol = "JREWARDS";
    bool public isActive;

    modifier notContract() {
        require(!_isContract(_msgSender()), "NOT_ALLOWED_CONTRACT");
        require(_msgSender() == tx.origin, "NOT_ALLOWED_PROXY");
        _;
    }
    modifier approvedCaller(){
        require(proxyContracts[msg.sender], "Invalid Caller");
        _;
    }
    constructor(string memory _uri, address _dev) 
        ERC1155(_uri)
    {
        baseURI = _uri;
        tokenIds[1] = true;
        tokenIds[2] = true;
        tokenIds[3] = true;
        tokenIds[4] = true;
        tokenIds[5] = true;
        isActive = true;
        _mint(_dev, 1, 1, "");
        _mint(_dev, 2, 1, "");
        _mint(_dev, 3, 1, "");
        _mint(_dev, 4, 1, "");
        _mint(_dev, 5, 1, "");
        _transferOwnership(_dev);
    }

    function appendToken(uint256 _tokenId)
        external 
        onlyOwner
    {
        tokenIds[_tokenId] = true;
    }

    function setRewardContract(address _contractAddress, bool _status) 
        external
        onlyOwner
    {
        proxyContracts[_contractAddress] = _status;
    }

    function burn(address _from, uint256[] calldata _ids, uint256[] calldata _amounts)
        external
        approvedCaller 
    {
        _burnBatch(_from, _ids, _amounts);
    }
    
    function setBaseURI(string calldata _uri) 
        external
        onlyOwner
     {
        baseURI = _uri;
    }

    function mint(address _to, uint256[] calldata _ids, uint256[] calldata _amounts)
        external
        approvedCaller
    {
        _mintBatch(_to, _ids, _amounts, "");
    }

    /// @notice Set signer for whitelist/redeem NFT.  
    /// @param _status state 
    function setActive(bool _status) 
        external 
        onlyOwner 
    {
        isActive = _status;
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function uri(uint256 typeId)
        public
        view                
        override
        returns (string memory)
    {
        require(
            tokenIds[typeId],
            "URI requested for invalid token type"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString()))
                : baseURI;
    }
}