// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../../utils/ERC721Claimable/ERC721ClaimableV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../utils/interfaces/IERC20Fixed.sol";

contract UniqERC721 is ERC721ClaimableV2 {
    uint256 internal _tokenNum = 0;

    mapping(uint256 => uint256) internal _tokenType;

    mapping(uint256 => mapping(bytes => bool)) internal _isHashUsed;

    address public administrator;

    event MintTokens(address indexed resquester, bytes indexed transactionHash, uint256[] indexed TokenIds, uint256 _networkId, uint256 tokenType);

    // ----- CONSTRUCTOR ----- //
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _ttokenUri,
        address paymentProxy
    )
        ERC721ClaimableV2(_name, _symbol, _ttokenUri, 750000)
    {
        administrator = msg.sender;
        transferOwnership(paymentProxy);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            bytes16 _HEX_SYMBOLS = "0123456789abcdef";
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), 20);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId))
            );
    }

    function baseTokenURI()
        public 
        view 
        override
        returns(string memory)
    {
        return string(
                abi.encodePacked(super.baseTokenURI(), toHexString(address(this)), "/")
            );
    }


    function setOwner(address _newOwner) external {
        require(msg.sender == administrator, "Only admin");
        transferOwnership(_newOwner);
    } 

    function setAdministrator(address _newOwner) external {
        require(msg.sender == administrator, "Only admin");
        require(_newOwner != address(0), "Cant be zero");
        administrator = _newOwner;
    } 

    // ----- VIEWS ----- //
    function contractURI() public pure returns (string memory) {
        return "https://www.extnd.tech/nft-collections/tradeableNFT";
    }

    function getTokenType(uint256 _tokenId) external view returns(uint256){
        return _tokenType[_tokenId];
    }

    function isHashUsed(bytes memory _transactionHash, uint256 _networkId) external view returns(bool){
        return _isHashUsed[_networkId][_transactionHash];
    }

    function batchMintSelectedIds(
        uint[] memory _ids,
        address[] memory _addresses
    ) external onlyOwner {
        uint len = _ids.length;
        require(len == _addresses.length, "Arrays length");
        uint256 i = 0;
        for (i = 0; i < len; i++) {
            _safeMint(_addresses[i], _ids[i]);
        }
    }

    /// Used by admin
    function mintNFTTokens(address _requesterAddress, uint256 _bundleId, uint256[] memory _tokenIds, uint256 _chainId, bytes memory _transactionHash) external{
        require(msg.sender == administrator, "Only admin");
        require(!_isHashUsed[_chainId][_transactionHash], "Cant be minted twice");
        uint256 len = _tokenIds.length;
        require(len!=0, "At least one token");
        _isHashUsed[_chainId][_transactionHash] = true;
        for(uint i=0; i<len;i++){
            _safeMint(_requesterAddress, _tokenIds[i]);
            _tokenType[_tokenIds[i]] = _bundleId;
        }
        emit MintTokens(_requesterAddress, _transactionHash, _tokenIds, _chainId, _bundleId);
    }

    function recoverERC20(address token) external {
        require(msg.sender == administrator, "Only admin");
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val > 0, "Nothing to recover");
        // use interface that not return value (USDT case)
        IERC20Fixed(token).transfer(owner(), val);
    }
}