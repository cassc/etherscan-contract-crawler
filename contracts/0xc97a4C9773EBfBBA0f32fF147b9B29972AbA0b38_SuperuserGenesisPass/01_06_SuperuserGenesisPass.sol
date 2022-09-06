// SPDX-License-Identifier: MIT
/**
 ______     __  __     ______   ______     ______     ______   __  __     __        
/\  ___\   /\ \/\ \   /\  == \ /\  ___\   /\  == \   /\  ___\ /\ \/\ \   /\ \       
\ \___  \  \ \ \_\ \  \ \  _-/ \ \  __\   \ \  __<   \ \  __\ \ \ \_\ \  \ \ \____  
 \/\_____\  \ \_____\  \ \_\    \ \_____\  \ \_\ \_\  \ \_\    \ \_____\  \ \_____\ 
  \/_____/   \/_____/   \/_/     \/_____/   \/_/ /_/   \/_/     \/_____/   \/_____/ 
                                                                                                                                                                                                                                                                                                                
POWERED BY http://theweb3studio.xyz/ 
*/
pragma solidity >= 0.8 .7 < 0.9 .0;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SuperuserGenesisPass is ERC721A, Ownable {
    // ======== SUPPLY ========
    uint256 public constant MAX_SUPPLY = 1337;
    uint256 public constant TEAM_RESERVED = 150;

    // ======== ROYALTY ========
    address private royaltyAddress;
    uint96 private royaltyBasisPoints = 1000; //10 * 100 = 10%
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // ======== SALE STATUS ========
    bool public paused = true;
    bool public isAllowlistSale = true;

    // ======== METADATA ========
    bool public isRevealed = false;
    string private baseTokenURI;
    string private unrevealedTokenURI;

    // ======== CONTRACT LEVEL METADATA ========
    string public contractURI;

    // ======== MERKLE ROOT ========
    bytes32 public merkleRoot;

    // ======== CONSTRUCTOR ========
    constructor() ERC721A("SuperuserGenesisPass", "SGP") {
        setRoyaltyAddress(0x0D82d111f375706B4480A24f028F41AE580CeD55);
        _mintERC2309(_msgSender(), TEAM_RESERVED);
    }

    modifier mintCompliance {
        require(!paused, "Sale has not started");
        require(_msgSender() == tx.origin, "Minting from contract not allowed");
        require(totalSupply() < MAX_SUPPLY, "Exceeds supply");
        _;
    }

    // ======== MINTING ========
    function allowlistMint(bytes32[] calldata _proof)
    external
    mintCompliance {
        require(isAllowlistSale, "Allowlist Sale has ended");
        require(_numberMinted(_msgSender()) < 1, "Already minted");
        require(
            MerkleProof.verify(
                _proof,
                merkleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Signer address mismatch"
        );
        _mint(_msgSender(), 1);
    }

    function publicMint()
    external
    mintCompliance {
        require(!isAllowlistSale, "Public Sale has not started");
        require(_numberMinted(_msgSender()) < 1, "Already minted");
        _mint(_msgSender(), 1);
    }

    function numberMinted(address _minter) view external returns(uint256) {
        return _numberMinted(_minter);
    }
    
    // ======== AIRDROP ========
    function airdrop(uint256 _quantity, address _receiver) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeds supply");
        _mint(_receiver, _quantity);
    }

    // ======== SETTERS ========
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setUnrevealedTokenURI(string memory _unrevealedTokenURI)
    public
    onlyOwner {
        unrevealedTokenURI = _unrevealedTokenURI;
    }

    function setIsRevealed(bool _reveal) external onlyOwner {
        isRevealed = _reveal;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }
    
    function setIsAllowlistSale(bool _state) public onlyOwner {
        isAllowlistSale = _state;
    }

    function setRoyaltyAddress(address _royaltyAddress) public onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    // ========= GETTERS ===========
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns(string memory) {
        require(
            _exists(tokenId),
            "ERC721aMetadata: URI query for nonexistent token"
        );

        if (!isRevealed) {
            return unrevealedTokenURI;
        }

        return string(
            abi.encodePacked(
                baseTokenURI,
                _toString(tokenId)
            )
        );
    }

    function _startTokenId()
    internal
    view
    virtual
    override(ERC721A)
    returns(uint256) {
        return 1;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
            TokenOwnership memory ownership = _ownershipAt(currentTokenId);

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    // ========= EIP-2981 ===========
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns(address receiver, uint256 royaltyAmount) {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return (royaltyAddress, (_salePrice * royaltyBasisPoints) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A)
    returns(bool) {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}