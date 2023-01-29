// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MsPuiYiOvercomeGenesis is Ownable, EIP712, ERC721A {
    string private _tokenBaseURI;
    uint256 public startTime;
    mapping(address => bool) public hasMinted;

    bytes32 public constant WHITELIST_TYPEHASH =
        keccak256("Whitelist(address buyer,uint256 nonce)");
    address public whitelistSigner;

    modifier isSenderWhitelisted(uint256 _nonce, bytes memory _signature) {
        require(
            getSigner(msg.sender, _nonce, _signature) == whitelistSigner,
            "XWLIST"
        );
        _;
    }

    modifier isSaleActive() {
        require(isSaleActivated(), "XSALE");
        _;
    }

    constructor()
        ERC721A("MsPuiYi Overcome Genesis", "PUIYIGENESIS")
        EIP712("PUIYIGENESIS", "1")
    {}

    function mint(uint256 _nonce, bytes memory _signature)
        external
        isSaleActive
        isSenderWhitelisted(_nonce, _signature)
    {
        require(!hasMinted[msg.sender], "MINTED");
        hasMinted[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function gift(address[] calldata receivers) external onlyOwner {
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], 1);
        }
    }

    function isSaleActivated() public view returns (bool) {
        return startTime > 0 && block.timestamp >= startTime;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function getSigner(
        address _buyer,
        uint256 _nonce,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(WHITELIST_TYPEHASH, _buyer, _nonce))
        );
        return ECDSA.recover(digest, _signature);
    }

    function setWhitelistSigner(address _address) external onlyOwner {
        whitelistSigner = _address;
    }

    function _startTokenId() internal pure override(ERC721A) returns (uint256) {
        return 1;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function _baseURI()
        internal
        view
        override(ERC721A)
        returns (string memory)
    {
        return _tokenBaseURI;
    }
}