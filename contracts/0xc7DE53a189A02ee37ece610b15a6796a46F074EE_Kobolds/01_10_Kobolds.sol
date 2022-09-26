// SPDX-License-Identifier: MIT


pragma solidity ^0.8.17;
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";

error SoldOut();
error SaleNotStarted();
error MintingTooMany();
error NotWhitelisted();
error Underpriced();
error MintedOut();
error MaxMints();
error ArraysDontMatch();
error ZeroAddress();
error NotAuthorized();
error NotLastContractStakedOn();
error NotApprovedStakingContract();
error NotApproved();
error TokenWasNotStaking();
error TokenAlreadyStaking();
error NotSender();

/// @title Kobold Contract Part of Titanforge.
/// @author 0xSimon_
/// @notice Uses ECDSA for sig verification, bitmaps for staking data, and implements soft-staking
/// @dev Inspired by optimizoor & azuki team bitmaps :)
contract Kobolds is ERC721AQueryable, Ownable {
    using ECDSA for bytes32;
    uint256 public constant maxSupply = 8888;
    uint256 private constant maxSupplyBeforeOG = 8000;
    uint256 public constant maxPublicMints = 2;
    uint256 private constant EXTRA_MINT_INFO_DATA_ENTRY_BITMASK = (1 << 32) -1;
    uint256 private constant NUM_MINTED_PUBLIC_BITPOS = 32;
    uint256 public whitelistMintPrice = .0188 ether;
    uint256 public publicMintPrice = .0188 ether;

    address private signer = 0x6884efd53b2650679996D3Ea206D116356dA08a9;
    address  private titans;

    string private baseURI;
    string private notRevealedUri;
    string private uriSuffix = ".json";

    bool public revealed;

    enum SaleStatus {
        INACTIVE,
        WHITELIST,
        PUBLIC,
        OG
    }
    SaleStatus public saleStatus = SaleStatus.INACTIVE;
    mapping(address => bool) private approvedStakingContract;
    mapping(address => bool) private approvedBurningContract;

    /*
    [0..159] Last Staking Contract To Initiate A Stake
    [160] isStaked bit
    [161...255] aux
    */
    mapping(uint256 => uint256) public packedTokenStakingData;
    uint256 private constant BITPOS_IS_STAKED = 160;
    uint256 private constant BITMASK_LAST_STAKED_CONTRACT = (1 << 160) - 1;

    constructor() ERC721A("Kobolds", "KBLDS") {
        setNotRevealedURI("ipfs://cid/hidden.json");
        _mint(_msgSender(),1);
    }

    function getContractTokenIsStakingOn(uint256 tokenId)
        public
        view
        returns (address)
    {
        return
            address(
                uint160(
                    packedTokenStakingData[tokenId] &
                        BITMASK_LAST_STAKED_CONTRACT
                )
            );
    }

    function unpackStakedTokenData(uint256 tokenId)
        public
        view
        returns (bool isStaked, address lastContractStakedOn)
    {
        lastContractStakedOn = address(
            uint160(
                packedTokenStakingData[tokenId] & BITMASK_LAST_STAKED_CONTRACT
            )
        );
        isStaked = (packedTokenStakingData[tokenId] >> BITPOS_IS_STAKED) == 1;
    }

    /*
    Function for frontend to check if a token is staking on a contract
    */
    function checkIfBatchIsStaked(uint256[] calldata tokenIds)
        external
        view
        returns (bool[] memory linkedStatus)
    {
        uint256 tokenIdsLength = tokenIds.length;
        linkedStatus = new bool[](tokenIdsLength);
        for (uint256 i = 0; i < tokenIdsLength;) {
            linkedStatus[i] =
                (packedTokenStakingData[tokenIds[i]] >> BITPOS_IS_STAKED) == 1;
                unchecked{++i;}
        }
    }

    function airdrop(address[] calldata accounts, uint256[] calldata amounts)
        external
        onlyOwner
    {
        if (accounts.length != amounts.length) revert ArraysDontMatch();
        uint256 supply = totalSupply();
        for (uint256 i; i < accounts.length;) {
            if (supply + amounts[i] > maxSupply) revert SoldOut();
            unchecked {
                supply += amounts[i];
            }
            _mint(accounts[i], amounts[i]);
            unchecked{++i;}
        }
    }

    function approveStakingContract(address _address) external onlyOwner {
        approvedStakingContract[_address] = true;
    }

    function dissaproveStakingContract(address _address) external onlyOwner {
        delete approvedStakingContract[_address];
    }

    /*
        ...............~~~~~~~~~~~~~~~...............
    *    Internal Staking Functions For Single Token ID
        ...............~~~~~~~~~~~~~~~...............
    */
    function startStake(uint256 tokenId) internal {
        uint256 _packedTokenStakingData = packedTokenStakingData[tokenId];
        //If token is already staking, the value will be greater than 0 since bitpos 160 will be 1
        // and address slot will be filled from bits [0...159], so we can revert
        if (_packedTokenStakingData > 0) revert TokenAlreadyStaking();
        if (!isApprovedForAll(ownerOf(tokenId), _msgSender()))
            revert NotApproved();
        //packedTokenStakingData bit at 160 = 1 and 0 ... 159 contains most recent staking contract
        packedTokenStakingData[tokenId] =
            (1 << BITPOS_IS_STAKED) |
            uint160(_msgSender());
    }

    function endStake(uint256 tokenId) internal {
        (bool isStaked, address lastContractStakedOn) = unpackStakedTokenData(
            tokenId
        );
        //Users must unstake from last contract staked on.address
        if (lastContractStakedOn != _msgSender())
            revert NotLastContractStakedOn();
        //Token Must Be Staked In Order To Unstake
        if (!isStaked) revert TokenWasNotStaking();
        //Users must  approve the staking contract before it can lock their NFTs.
            if (!isApprovedForAll(ownerOf(tokenId), _msgSender()))
            revert NotApproved();
        //Resets the Staking Data
        delete packedTokenStakingData[tokenId];
    }

    /*
        ...............~~~~~~~~~~~~~~~...............
    *      Batch Staking Functions For External Calls
        ...............~~~~~~~~~~~~~~~...............

    */
    function batchStake(uint256[] calldata tokenIds) external {
        //No Need To Check Zero Address Since It Is False In The Mapping
        if (!approvedStakingContract[_msgSender()])
            revert NotApprovedStakingContract();
        for (uint256 i; i < tokenIds.length;) {
            startStake(tokenIds[i]);
            unchecked{++i;}
        }
    }

    function batchUnstake(uint256[] calldata tokenIds) external {
        //No Need To Check Zero Address Since It Is False In The Mapping
        if (!approvedStakingContract[_msgSender()])
            revert NotApprovedStakingContract();
        for (uint256 i; i < tokenIds.length;) {
            endStake(tokenIds[i]);
            unchecked{++i;}
        }
    }

    /*
        ...............~~~~~~~~~~~~~~~...............
    *                   Mint Functions
        ...............~~~~~~~~~~~~~~~...............

    */

    /// @notice Allows whitelisted users to ming
    /// @dev Uses ECDSA signature recovery to verify signer
    /// @param amount specifies the amount of tokens a user wishes to mint
    /// @param max specifies the max a user can mint which is encoded in the signature
    /// @param signature signature that is passed in from frontend to allow whitelisted members to mint
    function whitelistMint(
        uint256 amount,
        uint256 max,
        bytes memory signature
    ) external payable {
        if (saleStatus != SaleStatus.WHITELIST) revert SaleNotStarted();
        if (totalSupply() + amount > maxSupplyBeforeOG) revert SoldOut();
        bytes32 hash = keccak256(abi.encodePacked("KBLD",max, _msgSender()));
        if (hash.toEthSignedMessageHash().recover(signature) != signer)
            revert NotWhitelisted();
        if (msg.value < whitelistMintPrice * amount) revert Underpriced();
        if (_numberMinted(_msgSender()) + amount > max) revert MaxMints();
        _mint(_msgSender(), amount);
    }
    function ogMint(
        uint256 amount,
        uint256 max,
        bytes memory signature
    ) external  {
        if (saleStatus != SaleStatus.OG) revert SaleNotStarted();
        if (totalSupply() + amount > maxSupply) revert SoldOut();
        bytes32 hash = keccak256(abi.encodePacked("KOG",max, _msgSender()));
        if (hash.toEthSignedMessageHash().recover(signature) != signer)
            revert NotWhitelisted();
        uint numOgMints = getNumMintedOG(_msgSender());
        if (numOgMints + amount > max) revert MaxMints();
        setNumMintedOG(_msgSender(),numOgMints + amount);
        _mint(_msgSender(), amount);
    }

    function publicMint(uint256 amount) external payable {
        if (saleStatus != SaleStatus.PUBLIC) revert SaleNotStarted();
        if (_msgSender() != tx.origin) revert NotSender();
        if (totalSupply() + amount > maxSupplyBeforeOG) revert SoldOut();
        uint numMinted = getNumMintedPublic(_msgSender());
        if (numMinted + amount > maxPublicMints) revert MaxMints();
        if (msg.value < publicMintPrice * amount) revert Underpriced();
        setNumMintedPublic(_msgSender(), (uint64(amount) + numMinted));
        _mint(_msgSender(), amount);
    }

    function getNumMintedPublic(address account)
        public
        view
        returns (uint256)
    {
        return (uint256(_getAux(account)) >> NUM_MINTED_PUBLIC_BITPOS) & EXTRA_MINT_INFO_DATA_ENTRY_BITMASK;
    }

    function getNumMintedWhitelist(address account)
        external
        view
        returns (uint256)
    {
        return _numberMinted(account);
    }

    function getNumMintedOG(address account) public view returns(uint) {
        return _getAux(account) & EXTRA_MINT_INFO_DATA_ENTRY_BITMASK;
    }
    function setNumMintedPublic(address account,uint num) internal {
        //Can't Overflow Since BITPOS = 32 and Max Public Mints = 2;
        uint numMintedOG = getNumMintedOG(account);
        uint preserveDataPlusNum = numMintedOG | (num << NUM_MINTED_PUBLIC_BITPOS);
        _setAux(account, uint64(preserveDataPlusNum));
    }
    function setNumMintedOG(address account, uint num) internal {
        //Cant Overflow Since Max Mints On OG = 1
        //Preserving Data For Good Practice Although We Don't Really Need To
        uint numMintedPublic = getNumMintedPublic(account);
        uint preserveDataPlusNum = (numMintedPublic << NUM_MINTED_PUBLIC_BITPOS) | num;
        _setAux(account,uint64(preserveDataPlusNum));
    }

    /*
    ...............~~~~~~~~~~~~~~~...............
    *              Burn Functions
    ...............~~~~~~~~~~~~~~~...............
*/
    function burnBatch(uint256[] calldata tokenIds) external {
        if (_msgSender() != titans) revert NotAuthorized();
        if (_msgSender() == address(0)) revert ZeroAddress();
        //We Will Check Inside The Titans Contract To Ensure We Burn From Correct Owner
        uint256 tokenIdsLength = tokenIds.length;
        for (uint256 i; i < tokenIdsLength;) {
            _burn(tokenIds[i]);
            unchecked{++i;}
        }
    }

    /*
        ...............~~~~~~~~~~~~~~~...............
    *                     Setters
        ...............~~~~~~~~~~~~~~~...............
    */
    function setTitans(address _titans) external onlyOwner {
        titans = _titans;
    }

    function setWhitelistMintPrice(uint256 price) external onlyOwner {
        whitelistMintPrice = price;
    }

    function setPublicMintPrice(uint256 price) external onlyOwner {
        publicMintPrice = price;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWhitelistOn() external onlyOwner {
        saleStatus = SaleStatus.WHITELIST;
    }

    function setPublicOn() external onlyOwner {
        saleStatus = SaleStatus.PUBLIC;
    }
    function setOgOn() external onlyOwner{
        saleStatus = SaleStatus.OG;
    }

    function turnSalesOff() external onlyOwner {
        saleStatus = SaleStatus.INACTIVE;
    }

    function switchReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /*
    ...............~~~~~~~~~~~~~~~...............
                     METADATA
    ...............~~~~~~~~~~~~~~~...............
*/
    function tokenURI(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _toString(tokenId),
                        uriSuffix
                    )
                )
                : "";
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721A) {
        //Top Bits Are Empty So This Will Work
        /// @dev Will work even if top bits arent clean
        //  bool isStaked = (packedTokenStakingData[startTokenId] >> BITPOS_IS_STAKED) == 1;
        //  if(isStaked) revert TokenAlreadyStaking();
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            bool isStaked = (packedTokenStakingData[tokenId] >>
                BITPOS_IS_STAKED) == 1;
            if (isStaked) revert TokenAlreadyStaking();
        }
    }

    /*///////////////////////////////////////////////////////////////
                           WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/
    function withdraw() external  onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}