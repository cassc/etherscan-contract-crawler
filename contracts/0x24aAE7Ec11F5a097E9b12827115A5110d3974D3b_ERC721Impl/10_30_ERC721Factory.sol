// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./Extension/ERC721Wrappable.sol";
import "./Extension/IERC721Royalty.sol";
import './Access/IERC721Firewall.sol';
import './IERC721Impl.sol';
import './IERC721Factory.sol';

contract ERC721Factory is IERC721Factory, ERC721Wrappable, IERC721Royalty {

    address public collection;
    IERC721Firewall public firewall;

    uint256 public fee;
    string public defaultUri;
    bool public mintingActive;

    // Modifiers
    modifier onlyWhenCollectionSet() {
        require(collection != address(0), "Factory: collection zero address!");
        _;
    }

    modifier onlyWhenMintable(address minter, uint256 amount) {
        (bool allowed, string memory message) = canMint(minter, amount);
        require(allowed, message);
        _;
    }
    
    constructor(address collection_, uint256 fee_, address firewall_, string memory defaultUri_) {
        setCollection(collection_);
        setMintingActive(false);
        setFee(fee_);
        setFirewall(firewall_);
        setDefaultUri(defaultUri_);
    }

    // Minting
    function mint() public payable override {
        mint(_msgSender(), 1);
    }

    function mint(uint256 amount) public payable override {
        mint(_msgSender(), amount);
    }

    function mint(address to, uint256 amount) public payable override {
        require(_msgSender() == owner() || _msgSender() == address(this) || fee * amount == msg.value,
            'Factory: provided fee does not match required amount!');
        _mint(to, amount);
    }

    function mintAdmin() public payable override {
        mintAdmin(_msgSender(), 1);
    }

    function mintAdmin(uint256 amount) public payable override {
        mintAdmin(_msgSender(), amount);
    }

    function mintAdmin(address to, uint256 amount) public payable override onlyOwner {
        (bool allowed, ) = firewall.canAllocate(to, amount);
        if (!allowed) firewall.setAllocation(to, firewall.currentAllocation(to) + amount);
        mint(to, amount);
    }

    function _mint(address to, uint256 amount) internal onlyWhenMintable(to, amount) {
        firewall.allocate(to, amount);
        bool isDefaultSet = keccak256(bytes(defaultUri)) != keccak256(bytes(""));
        if (isDefaultSet) {
            string[] memory uris = new string[](amount);
            for (uint i=0; i<amount; i++) {
                uris[i] = defaultUri;
            }
            uint256 lastTokenId = IERC721Impl(collection).totalMinted();
            IERC721Impl(collection).mintTo(to, amount, uris);
            for (uint i=0; i<amount; i++) {
                _requestUri(lastTokenId+i+1);
            }
        } else {
            IERC721Impl(collection).mintTo(to, amount, new string[](0));
        }

        emit TokenMinted(to, amount);
    }

    function _requestUri(uint256 tokenId) internal virtual {
        // DO NOTHING, ABSTRACT METHOD
    }

    function _resolveUri(uint256 tokenId, string memory uri) internal virtual {
        // DO NOTHING, ABSTRACT METHOD
    }

    function canMint(address minter, uint256 amount) public override view returns (bool, string memory) {
        bool allowed = false;
        string memory message = "";

        if (collection == address(0)) {
            return (false, "Factory: cannot mint yet");
        }
        allowed = IERC721Impl(collection).canMint(amount);
        if (!allowed) {
            return (false, "Factory: cannot mint more");
        }
        (allowed, message) = firewall.canAllocate(minter, amount);
        if (!allowed) {
            return (false, message);
        }
        if (_msgSender() != owner()) {
            if (!mintingActive) {
                return (false, "Factory: minting disabled!");
            }
            if (firewall.isWhitelistActive() && !firewall.isWhitelisted(minter)) {
                return (false, "Factory: not whitelisted!");
            }
        }
        return (true, "");
    }

    function setMintingActive(bool enabled_) public onlyOwner {
        mintingActive = enabled_;
        emit MintingSet(enabled_);
    }

    function setFee(uint256 fee_) public onlyOwner {
        // zero fee_ is accepted
        fee = fee_;
        emit FeeSet(fee_);
    }   

    function setCollection(address collection_) public onlyOwner {
        collection = collection_;
        emit CollectionSet(collection_);
    }

    function setFirewall(address firewall_) public onlyOwner {
        firewall = IERC721Firewall(firewall_);
        emit FirewallSet(firewall_);
    }

    function setDefaultUri(string memory uri_) public onlyOwner {
        defaultUri = uri_;
        emit DefaultUriSet(uri_);
    }

    // Payments & Ownership
    function balanceOf() external view override returns(uint256) {
        return address(this).balance;
    }

    function withdraw(address to) public override onlyOwner {
        uint256 amount = address(this).balance;
        withdraw(to, amount);
    }

    function withdraw(address to, uint256 amount) public override onlyOwner {
        require(to != address(0), 'Factory: cannot withdraw fees to zero address!');
        payable(to).transfer(amount);
        emit Withdrawn(_msgSender(), to, amount);
    }

    // Owable ERC721 functions
    function setBaseURI(string memory _uri) external override onlyOwner onlyWhenCollectionSet {
        IERC721Royalty(collection).setBaseURI(_uri);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external override onlyOwner onlyWhenCollectionSet {
        IERC721Royalty(collection).setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external override onlyOwner onlyWhenCollectionSet {
        IERC721Royalty(collection).deleteDefaultRoyalty();
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external override onlyOwner onlyWhenCollectionSet {
        IERC721Royalty(collection).setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external override onlyOwner onlyWhenCollectionSet {
        IERC721Royalty(collection).resetTokenRoyalty(tokenId);
    }
}