// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Anniverse365 is ERC721Enumerable, Ownable {    
    using Address for address;
    uint256 constant _maxTokens = 366; // max NFT tokens supply    

    uint256 _mintTimeSWhite = 1672545600;  // white mint start time
    uint256 _mintTimeEWhite = 1672718400;  // white mint end time
    bytes32 _merkleRoot = 0x836aa75d649c817e3f4e1c337a667a7cd6226080c20b9169e3897aee7ca8ce28; // white merkleRoot

    uint256 _mintTimeS = 1673409600;  // start mint time
    uint256 _mintTimeE = 1674100800;  // end mint time
    mapping(address => bool) public _claimed;  // claimed address
    address public _withdrawAddress = 0x3E0DCbd1640F5AD9af76BB95fC007aA6eE1f5318; // withdraw address
    string _myBaseUri = 'https://api.the365.io/token/';

    event PublicMintConfigUpdated(uint256 startTime, uint256 endTime);
    event WhitelistMintConfigUpdated(uint256 startTime, uint256 endTime, bytes32 merkleRoot);
    event WithdrawAddressConfigUpdated(address withdrawAddress);
    event Withdraw(address from, address to, uint amount);
    event WithdrawERC20(address from, address to,address tokenAddress, uint amount);
    event Donate(address from, uint256 amount);

    constructor() ERC721("Anniverse365", "ANV") {}

    function _baseURI() 
        internal 
        view 
        override(ERC721) 
        returns (string memory) 
    {    
        return _myBaseUri;
    }

    function setBaseUri(string memory str) 
        external 
        onlyOwner 
    {
        _myBaseUri = str;
    }

    function mintProcess(address to, uint256 tokenId) private
    {
        require(tokenId < _maxTokens, "invalid tokenId");
        require(!_exists(tokenId),"Token already claimed");
        require(_claimed[to] == false, "address already claimed");
        _claimed[to] = true;
        _safeMint(to, tokenId);
    }    

    function ownerMint(address[] calldata tos, uint256[] calldata tokens) 
        external 
        onlyOwner 
    {
        require(tos.length > 0 && tos.length == tokens.length, "invalid input");
        for (uint256 i; i < tos.length; i++) {
            mintProcess(tos[i], tokens[i]);
        }
    }

    function setWhiteMint(uint256 startTime, uint256 endTime, bytes32 merkleRoot) 
        external 
        onlyOwner 
    {
        _mintTimeSWhite = startTime;
        _mintTimeEWhite = endTime;
        _merkleRoot = merkleRoot;

        emit WhitelistMintConfigUpdated(startTime, endTime, merkleRoot);
    }

    function whiteMint(bytes32[] calldata merkleProof, uint256 tokenId) 
        external 
    {
        require(_mintTimeSWhite > 0 && block.timestamp >= _mintTimeSWhite, "invalid white mint period");
        require(_mintTimeEWhite > 0 && block.timestamp < _mintTimeEWhite, "invalid white mint period");
        require(checkWhite(merkleProof, _msgSender()) == true, "invalid merkle proof");
        mintProcess(_msgSender(), tokenId);        
    }

    function checkWhite(bytes32[] calldata merkleProof, address checkAddress)
        public
        view
        returns (bool)
    {
        require(_merkleRoot != 0x0, "invalid white mint merkle");
        bytes32 leaf = keccak256(abi.encodePacked(checkAddress));
        return MerkleProof.verify(merkleProof, _merkleRoot, leaf);
    }

    function setMint(uint256 startTime, uint256 endTime) 
        external 
        onlyOwner 
    {
        _mintTimeS = startTime;
        _mintTimeE = endTime;

        emit PublicMintConfigUpdated(startTime, endTime);
    }

    function mint(uint256 tokenId) 
        external 
    {
        uint256 t = block.timestamp;
        require(_mintTimeS > 0 && t >= _mintTimeS, "invalid mint period");
        require(_mintTimeE > 0 && t < _mintTimeE, "invalid mint period");
        mintProcess(_msgSender(), tokenId);
    }

    function ownerTokens(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return (tokenIds);
    }

    function setWithdrawAddress(address withdrawAddress) 
        external 
        onlyOwner 
    {
        _withdrawAddress = withdrawAddress;
        emit WithdrawAddressConfigUpdated(withdrawAddress);
    }

    function withdraw() 
        external 
        onlyOwner 
    {
        require(_withdrawAddress != address(0), "invalid withdrawAddress");
        uint256 balance = address(this).balance;
        Address.sendValue(payable(_withdrawAddress), balance);
        emit Withdraw(_msgSender(), _withdrawAddress, balance);
    }

    function withdrawERC20(address token,address to, uint256 amount)
         external
         onlyOwner
    {
        require(to != address(0), "invalid to address");
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(amount <= balance, "balance is low"); 
        IERC20(token).transfer(to, amount);
        emit WithdrawERC20(_msgSender(), to, token, amount);
    }

    function donate() public payable {
        emit Donate(_msgSender(), msg.value);
    }

    receive() external payable  { 
        donate();
    }
}