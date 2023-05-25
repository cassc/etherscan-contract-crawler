// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./kpst.sol";

pragma solidity ^0.8.0;

/*
    Knights of Degen Drop!
    Minting 8,888 Knight NFTs at 0.088 ETH each.
*/
contract Knights is ERC721Enumerable, AccessControl, ERC721URIStorage, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    address private constant TREASURY_ADDRESS = 0xbfCF42Ef3102DE2C90dBf3d04a0cCe90eddA6e3F;

    Counters.Counter private totalMinted;

    // Connection to other contracts
    Kpst private immutable kpst;

    bytes32 public constant EARLY_ACCESS = keccak256("EARLY_ACCESS_ROLE");

    // Redemption Festival
    Counters.Counter private _redemptionTracker;
    uint256 public constant MAX_REDEMPTIONS = 2225;
    // For each mint pass, the number you can additionally purchase
    uint256 public constant REDEEM_LIMIT = 2;

    // Set when the redemption festival is open or closed
    bool private _presaleOpen = false;

    // Limit the total supply to 8,888 knights of degen. 25 can be minted at a time. Max 88 per address.
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant MAX_MINTS_PER_ATTEMPT = 25;
    uint256 public constant MAX_TOTAL_PUBLIC_MINTS_PER_ADDRESS = 88;
    mapping(address => uint) private publicSaleMintCountPerAddress;

    // Flag that the sale has started.
    bool private _saleStarted = false;

    // Default price for the drop
    uint256 private _defaultPrice = 88 * 10**15; // This is .088 eth

    // Base token URI
    string private _baseTokenURI;

    // Is the art and metadata revealed?
    bool private _isRevealed = false;

    // Starting index to offset the random generation for even more randomness.
    uint256 private _startingIndex;
    uint256 private _blockStartNumber;

    address public kpstAddressSet;
    
    constructor(
        address kpstAddress
    ) ERC721("Knights of Degen", "KNIGHTS") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        kpstAddressSet = kpstAddress;
        kpst = Kpst(kpstAddress);
    }

    function getKpstAddress() external view returns (address) {
        return kpstAddressSet;
    }

    /*
        You can redeem anytime you want whether in the redemption or not, you just are not able to get the exclusive mints.
    */
    function redeemOutsideWindow(uint256 _redemptionCount) external nonReentrant payable {
        require(_redemptionCount > 0, "You must be redeeming at least one mint ticket");
        require(kpst.balanceOf(msg.sender) >= _redemptionCount, "You must own as many tickets as you are attempting to redeem");
        uint256[] memory tokens = kpst.walletOfOwner(msg.sender);
        require(tokens.length >= _redemptionCount, "Safety check that you have enough tokens");
        uint256 totalSupply = totalMinted.current();
        uint256 mintIndex;
        // Redeem and mint per mint pass
        for(uint256 i = 0; i < _redemptionCount; i ++) {
            kpst.burnForRedemption(tokens[i]);
            _safeMint(msg.sender, totalSupply + mintIndex + 1);
            totalMinted.increment();
            _redemptionTracker.increment();
            mintIndex += 1;
        }
    }

    /*
        During the redemption festival you can redeem your SHIELD token for 1 KNIGHT token.
        You also get exclusive access to purchase up to 2 KNIGHT tokens for every SHIELD you have.
        ie. if you have 2 SHIELDS (mint tickets), you can purchase up to 4 additional KNIGHTs.
    */
    function redeem(uint256 _redemptionCount, uint256 _buyCount) external nonReentrant payable {
        require(_redemptionCount > 0 && _redemptionCount <= 50 && _buyCount <= 100, "Safe limits are being enforced for your protection");
        require(_presaleOpen == true, "Presale redeem period must be open");
        require(_saleStarted == false, "Once sale has started, no more redemption with purchase option");
        require(_buyCount <= REDEEM_LIMIT * _redemptionCount, "You can only buy up to two knights per mint ticket");
        require(kpst.balanceOf(msg.sender) >= _redemptionCount, "You must own as many tickets as you are attempting to redeem");
        uint256[] memory tokens = kpst.walletOfOwner(msg.sender);
        require(tokens.length >= _redemptionCount, "Safety check that you have enough tokens");
        require(msg.value >= (_defaultPrice * _buyCount), "You must pay for your additional purchases");
        

        // We will now mint you your _redemptionCount + _buyCount tickets
        uint256 totalSupply = totalMinted.current();
        uint256 mintIndex;
        // Redeem and mint per mint pass
        for(uint256 i = 0; i < _redemptionCount; i ++) {
            kpst.burnForRedemption(tokens[i]);
            _safeMint(msg.sender, totalSupply + mintIndex + 1);
            totalMinted.increment();
            _redemptionTracker.increment();
            mintIndex += 1;
        }
        for(uint256 i = 0; i < _buyCount; i ++) {
            _safeMint(msg.sender, totalSupply + mintIndex + 1);
            totalMinted.increment();
            mintIndex += 1;
        }
    }

    /*
        An admin can airdrop a KNIGHT to a specific address.
        Restricted so that we do not go over the max supply.
        Restricted so that we leave enough for remaining redemptions.
    */
    function airdrop(address _target, uint256 _count) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must be an admin in order to airdrop");
        uint256 totalSupply = totalMinted.current();
        require(totalSupply + _count <= MAX_SUPPLY, "Can not mint more than the max supply");
        require(totalSupply + _count <= (MAX_SUPPLY - (MAX_REDEMPTIONS - _redemptionTracker.current())), "Can not more than would allow us to redeem");
        for (uint256 index; index < _count; index++) {
            _safeMint(_target, totalSupply + index+1);
            totalMinted.increment();
        }
    }

    /*
        Mint a KNIGHT nft.
        Requires:
            - sale open
            - not going to mint more than the max supply
            - not going to mint too many that late redeemers can not redeem
            - minting at least 1
            - not minting more than they should per attempt
            - ensuring they pay enough
            - limitng to 88 total tokens during public sale
    */
    function mint(uint256 _count) public payable {
        require(
            isSaleOpen() == true,
            "The Knights sale is not currently open."
        );

        uint256 totalSupply = totalMinted.current();
        require(
            totalSupply + _count <= MAX_SUPPLY,
            "A transaction of this size would surpass the token limit."
        );
        require(totalSupply + _count <= (MAX_SUPPLY - (MAX_REDEMPTIONS - _redemptionTracker.current())), "Can not more than would allow us to redeem");

        require(_count > 0, "Must mint something");
        require(_count <= MAX_MINTS_PER_ATTEMPT, "Exceeds the max token per transaction limit.");
        require(
            msg.value >= _defaultPrice * _count,
            "The value submitted with this transaction is too low."
        );
        
        require(
            publicSaleMintCountPerAddress[msg.sender] + _count <= MAX_TOTAL_PUBLIC_MINTS_PER_ADDRESS, 
            "You are limited to 88 total tokens during the public sale"
        );

        for (uint256 i; i < _count; i++) {
            _safeMint(msg.sender, totalSupply + i+1);
            totalMinted.increment();
        }
        publicSaleMintCountPerAddress[msg.sender] = publicSaleMintCountPerAddress[msg.sender] + _count;
        
    }

    function getTotalMintCount() public view returns (uint256) {
        return totalMinted.current();
    }

    function setSaleStarted(bool _ss) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must be an admin to set sale started");
        _blockStartNumber = block.number;
        _saleStarted = _ss;
    }

    function getPrice() public view returns (uint256) {
        return _defaultPrice;
    }

    function getRedemptionCount() public view returns (uint256) {
        return _redemptionTracker.current();
    }

    function isPresaleOpen() public view returns (bool) {
        return _presaleOpen;
    }

    function isSaleOpen() public view returns (bool) {
        return _saleStarted;
    }

    function setBaseURI(string memory baseURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must be an admin to set the base URI");
        require(_isRevealed == false, "Can no longer set the base URI after reveal");
        _baseTokenURI = baseURI;
    }

    // Set that we have revealed the final base token URI, and lock the reveal so that the token URI is permanent
    function setRevealed() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only an admin can finalize the reveal");
        require(_isRevealed != true, "Can no longer set the reveal once it has been revealed");
        _isRevealed = true;
    }

    function setPresaleOpen(bool _isOpen) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only an admin can finalize the presale openness");
        _presaleOpen = _isOpen;
    }

    function isRevealed() public view returns (bool) {
        return _isRevealed;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
   
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        }

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Always withdraw to the treasury address. Allow anyone to withdraw, such that there can be no issues with keys.
    function withdrawAll() public payable {
        require(payable(TREASURY_ADDRESS).send(address(this).balance));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function setStartingIndex() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must be an admin to set starting index");
        require(_startingIndex == 0, "Starting index can only be set once from the default value of 0");
        _startingIndex = calculateStartingIndex(_blockStartNumber, MAX_SUPPLY);
        if(_startingIndex == 0) {
            _startingIndex++;
        }
    }

    function getStartingIndex() public view returns (uint256) {
        return _startingIndex;
    }

    function calculateStartingIndex(uint256 blockNumber, uint256 collectionSize)
        internal
        view
        returns (uint256)
    {
        return uint256(blockhash(blockNumber)) % collectionSize;
    }

}