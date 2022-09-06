// SPDX-License-Identifier: UNLICENSED
// Author: DMB   
// Date: Aug 4th, 2022

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract Contract is 
    Initializable, 
    ERC721Upgradeable, 
    ERC721URIStorageUpgradeable, 
    OwnableUpgradeable, 
    PausableUpgradeable,
    UUPSUpgradeable
{
//----------------------------------PROXY------------------------------------\\
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("DreamWorld", "DRM");
        __ERC721URIStorage_init();
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        isMintOpen = false;
        isAlMintOpen = false;
        merkleRoot = 0x730c47420e09b5fe9bb900c0974fae5156f743760e7b9aeef6329aa228f85b1f;
        maxSupply = 5700;
        alMaxMint = 2;
        mintPrice = 0.07 ether;
        tokenIdCounter = 0;
        adminAddress = 0xfD7d91034EB3e110d51C649C890F041381A7707B;
        base_uri = "ipfs:///";
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
//---------------------------------EVENTS------------------------------------\\
    event MetaDataReleased();

    event AlMintToggle(bool isOpen);

    event PublicMintToggle(bool isOpen);
//-------------------------------STATE VARS----------------------------------\\
    mapping(address => uint256) public claimedToken;

    bool public isMintOpen;
    bool public isAlMintOpen;
    bytes32 public merkleRoot;
    uint128 public maxSupply;
    uint128 public alMaxMint;
    uint256 public mintPrice;
    uint256 public tokenIdCounter;
    address private adminAddress;
    string public base_uri;
//----------------------------------USER-------------------------------------\\
    /** @notice The public mint requires:
    *   - Admin or owner to have opened mint
    *   - Available supply
    *   - Proper fee sent in tx
    */
    function publicMint() public payable whenNotPaused {
        ++tokenIdCounter;
        uint256 tokenId = tokenIdCounter;
        require(isMintOpen, 
               "Contract: Public minting is not available at this time.");
        require(tokenId <= maxSupply, 
                "Contract: This minting would exceed max token supply.");
        require(msg.value == mintPrice,
                "Contract: Please review mint price.");

        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(
            uint2str(tokenId), ".json")));
    }

    /** @notice The allowlist  mint requires:
    *   - Admin or owner to have opened AL mint
    *   - Available supply
    *   - Proper fee sent in tx
    *   - Proof holder to have minted less than AL limit
    *   - Valid proof
    */
    function allowListMint(bytes32[] calldata _proof) 
        public payable whenNotPaused {
            ++tokenIdCounter;
            uint256 tokenId = tokenIdCounter;
            require(isAlMintOpen, 
                    "Contract: Allowlist (WL) minting is not available at this time.");
            require(tokenId <= maxSupply, 
                    "Contract: This minting would exceed max token supply.");
            require(msg.value == mintPrice,
                    "Contract: Please review mint price.");
            require(claimedToken[msg.sender] < alMaxMint,
                    "Contract: This wallet address has already claimed available pre-sale NFT.");
            require(MerkleProofUpgradeable.verify(_proof, merkleRoot, toBytes32(msg.sender)) == true, 
                    "Contract: Invalid proof.");

            claimedToken[msg.sender]++;
            _mint(msg.sender, tokenId);
            _setTokenURI(tokenId, string(abi.encodePacked(
                uint2str(tokenId), ".json")));
    }

    /** @notice Withdrawing funds available to owner/admin accounts.
    */
    function withdrawFunds(uint256 _amount) external onlyPrivileged {
        payable(owner()).transfer(_amount);
    }

//----------------------------------ACCESS-----------------------------------\\
    modifier onlyPrivileged() {
        require(isPrivileged(_msgSender()),
            "Contract: Caller is not an Admin or contract owner.");
        _;
    }
    
    /** @notice isPrivileged is helper function for the associated onlyPrivileged
    *   modifier. Together they allow owner and admin the same access for where
    *   the modifier is applied.
    */ 
    function isPrivileged(address _account) public view returns (bool priv) {
        bool _return;
        _account == owner() || _account == adminAddress ?
            _return = true :
            _return = false;

        return _return;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
//--------------------------------HELPERS------------------------------------\\
    /** @notice The toBytes32 function is a helper to handle casting an address
    *   to bytes32.
    */
    function toBytes32(address addr) pure internal returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    /** @notice The uint2str function is a helper for handling the 
    *   concatenation of string numbers.
    */
    function uint2str(uint _int) internal pure returns (string memory) {
        if (_int == 0) {
            return "0";
        }
        uint j = _int;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_int != 0) {
            unchecked { bstr[k--] = bytes1(uint8(48 + _int % 10)); }
            _int /= 10;
        }
        return string(bstr);
    }

//--------------------------------SETTERS-----------------------------------\\
    function setSupply(uint128 _newSupply) 
        external onlyPrivileged {
            maxSupply = _newSupply;
    }

    function setPublicMint(bool _state)
        external onlyPrivileged {
            isMintOpen = _state;
            emit PublicMintToggle(_state);
    }

    function setAlMint(bool _state)
        external onlyPrivileged {
            isAlMintOpen = _state;
            emit AlMintToggle(_state);
    }

    function setMetaData(string calldata _uri) 
        external onlyPrivileged {
            base_uri = _uri;
            emit MetaDataReleased();
    }
//--------------------------------OVERRIDES----------------------------------\\
    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
            super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory) {
            return super.tokenURI(tokenId);
    }

     function _baseURI() internal view virtual override returns (string memory) {
        return base_uri;
    }
}