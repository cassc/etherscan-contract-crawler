//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../libraries/ECDSALibrary.sol";
import "./ERC721A.sol";
import "./interfaces/IERC721A.sol";
import "./interfaces/ITheNFTIslands.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IIslandToken.sol";

contract TheNFTIslands is ITheNFTIslands, ERC721A, Ownable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    // Previous launch
    ITheNFTIslands public previousLaunch;

    // staking contract
    IStaking public staking;
    IIslandToken private tokenContract;

    string private _baseTokenURI;
    bool public isUriFrozen;

    // presale times
    uint256 public presaleTime = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe;
    uint256 public publicTime = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // presale price for each token types
    uint256 private priceStd = 0.1 ether;
    uint256 private priceLrg = 0.15 ether;
    uint256 private pricePrm = 0.2 ether;

    // max supply for each token types
    uint256 private standardMaxSupply = 2990;
    uint256 private largeMaxSupply = 2500;
    uint256 private premiumMaxSupply = 1500;

    uint256 private maxBundles = 1000;

    // current supply for each token types
    uint256 private standardCurrentSupply = 73;
    uint256 private largeCurrentSupply = 40;
    uint256 private premiumCurrentSupply = 57;

    uint256 private bundleCurrentSupply = 25;

    /*
     * Max mint per transaction per token type
     */
    uint256 private MAX_MINT_STD = 2;
    uint256 private MAX_MINT_LRG = 1;
    uint256 private MAX_MINT_PRM = 1;

    /*
     * 0: standard
     * 1: large
     * 2: premium
     */
    mapping(uint256 => uint256) private tokenType;

    /**
     * nonce used for free mints
     */
    mapping(address => uint256) public nonces;

    /**
     * Payment distribution and addresses
     */
    uint256 internal constant totalShares = 1000;
    uint256 internal totalReleased;
    mapping(address => uint256) internal released;
    mapping(address => uint256) internal shares;
    address internal constant project = 0x6e5c5a1b0Bb40e03f7294F80D63ad8DFBf42a616;
    address internal constant shareHolder2 = 0x8f5B57E579E2C1C496Cd5edC45C9849115990AaE;
    address internal constant shareHolder3 = 0x88EE4c10A7c7D869EB45Eb1b4F9e7B9cA06FA2f4;
    address internal constant shareHolder4 = 0x8faF50473e546c3f9d7182AFDADb8788C2085C89;
    address internal constant shareHolder5 = 0x830CBf2c819DB0F56e61252E8d80c0778f58bbf3;
    address internal constant shareHolder6 = 0x17B170226350e59640051144CEB2EFE0979E4689;
    address internal constant shareHolder7 = 0xc1C6C3744143c3f3A8573B74e527e58aA9Bf8302;
    address internal constant shareHolder8 = 0x47Dba548DfB5dAc498480511BADD8001A11E6D6e;

    constructor() ERC721A("The NFT Islands", "TNI") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SIGNER_ROLE, msg.sender);

        shares[project] = 620;
        shares[shareHolder2] = 145;
        shares[shareHolder3] = 40;
        shares[shareHolder4] = 30;
        shares[shareHolder5] = 15;
        shares[shareHolder6] = 15;
        shares[shareHolder7] = 10;
        shares[shareHolder8] = 125;

        // set unrevealed metadata
        _baseTokenURI = "https://api.thenftislands.io/metadata/";

        previousLaunch = ITheNFTIslands(0xC20eE631d4dD4d66Fb536d1A415D8F7073B57689);

        _mint(address(this), 170);
    }

    // Get Prices
    function prices() external view returns(uint256, uint256, uint256) {
      return (priceStd, priceLrg, pricePrm);
    }

    // Get Current circulating supplies
    function currentSupplies() external view returns(uint256, uint256, uint256, uint256) {
      return (standardCurrentSupply, largeCurrentSupply, premiumCurrentSupply, bundleCurrentSupply);
    }

    // Get maximum supplies
    function maxSupplies() external view returns(uint256, uint256, uint256) {
      return (standardMaxSupply, largeMaxSupply, premiumMaxSupply);
    }

    // set staking address
    function setContracts(IStaking _staking, IIslandToken _tokenContract) external onlyOwner {
        staking = IStaking(_staking);
        tokenContract = IIslandToken(_tokenContract);
    }

    // get max supply of the collection
    function getMaxSupply() external view returns (uint256) {
        return premiumMaxSupply + largeMaxSupply + standardMaxSupply;
    }

    // change presalePrice for standard token
    function setStandardPrice(uint256 newPriceInWei) external onlyOwner {
        priceStd = newPriceInWei;
    }

    /*
     * change price of large islands in presale
     *
     * @param newPriceInWei: price in wei
     *
     */
    function setLargePrice(uint256 newPriceInWei) external onlyOwner {
        priceLrg = newPriceInWei;
    }

    /*
     * change price of premium islands in presale
     *
     * @param newPriceInWei: price in wei
     *
     */
    function setPremiumPrice(uint256 newPriceInWei) external onlyOwner {
        pricePrm = newPriceInWei;
    }

    /*
     * change max mint per transaction
     *
     * @param _maxStd: max number of standard token per transaction
     * @param _maxLrg: max number of large token per transaction
     * @param _maxPrm: max number of premium token per transaction
     *
     */
    function setMaxPerTransaction(
      uint256 _maxStd,
      uint256 _maxLrg,
      uint256 _maxPrm
    ) external onlyOwner {
        MAX_MINT_STD = _maxStd;
        MAX_MINT_LRG = _maxLrg;
        MAX_MINT_PRM = _maxPrm;
    }

    /**
     * reduce premium supply
     *
     * Error messages:
     * - T0 : "Supply can not be increased"
     * - T1 : "Supply has to be greater than totalSupply"
     */
    function reducePremiumMaxSupply(uint256 newSupply) external onlyOwner {
        require(newSupply < premiumMaxSupply, "T0");
        require(newSupply >= premiumCurrentSupply, "T1");
        premiumMaxSupply = newSupply;
    }

    /**
     * reduce large supply
     *
     * Error messages:
     * - T0 : "Supply can not be increased"
     * - T1 : "Supply has to be greater than totalSupply"
     */
    function reduceLargeMaxSupply(uint256 newSupply) external onlyOwner {
        require(newSupply < largeMaxSupply, "T0");
        require(newSupply >= largeCurrentSupply, "T1");
        largeMaxSupply = newSupply;
    }

    /**
     * reduce standard supply
     *
     * Error messages:
     * - T0 : "Supply can not be increased"
     * - T1 : "Supply has to be greater than totalSupply"
     */
    function reduceStandardMaxSupply(uint256 newSupply) external onlyOwner {
        require(newSupply < standardMaxSupply, "T0");
        require(newSupply >= standardCurrentSupply, "T1");
        standardMaxSupply = newSupply;
    }

    /*
     * set starting time of presale
     *
     * @param newTime: timestamp in seconds of the start of the presale
     *
     */
    function setTimePresale(uint256 newTime) external onlyOwner {
        presaleTime = newTime;
    }

    /*
     * set starting time of the public sale
     *
     * @param newTime: timestamp in seconds of the start of the public sale
     *
     */
    function setTimePublic(uint256 newTime) external onlyOwner {
        publicTime = newTime;
    }

    /*
     * mint tokens in public sale
     *
     * @param quantityStd: standard tokens quantity
     * @param quantityLrg: large tokens quantity
     * @param quantityPrm: premium tokens quantity
     * @param stake: stake your token immediately
     * @param bundle: mint a bundle
     *
     * Error messages:
     *  - T3: "Public not started"
     *  - T5: "Max quantity per transaction reached"
     */
    function publicMint(
        uint256 quantityStd,
        uint256 quantityLrg,
        uint256 quantityPrm,
        bool stake,
        bool bundle
    ) external payable {
        require(block.timestamp >= publicTime, "T3");
        require(quantityStd <= MAX_MINT_STD && quantityLrg <= MAX_MINT_LRG && quantityPrm <= MAX_MINT_PRM, "T5");

        intervalMint(quantityStd, quantityLrg, quantityPrm, stake, bundle);
    }

    /*
     * mint tokens in presale
     *
     * @param quantityStd: standard tokens quantity
     * @param quantityLrg: large tokens quantity
     * @param quantityPrm: premium tokens quantity
     * @param stake: stake your token immediately
     * @param bundle: mint a bundle
     * @param signature: whitelist signature
     *
     * Error messages:
     *  - T6: "Presale not started"
     *  - T7: "Presale is closed, please mint in public"
     *  - T9: "You are not whitelisted"
     */
    function presaleMint(
        uint256 quantityStd,
        uint256 quantityLrg,
        uint256 quantityPrm,
        bool stake,
        bool bundle,
        bytes calldata signature
    ) external payable {

        require(block.timestamp >= presaleTime, "T6");
        require(block.timestamp < publicTime, "T7");

        require(hasRole(SIGNER_ROLE, ECDSALibrary.recover(abi.encodePacked(msg.sender), signature)), "T9");

        intervalMint(quantityStd, quantityLrg, quantityPrm, stake, bundle);
    }

    /*
     * interval logic common to presale and public
     *
     * @param quantityStd: standard tokens quantity
     * @param quantityLrg: large tokens quantity
     * @param quantityPrm: premium tokens quantity
     * @param stake: stake your token immediately
     * @param bundle: mint a bundle
     *
     * Error messages:
     *  - T2: "Wrong price"
     *  - T4: "Collection's max supply reached"
     *  - T5: "Max quantity per transaction reached"
     *  - T8: "All bundles sold out"
     *  - T14: "Transaction is not a bundle"
     */
    function intervalMint(uint256 quantityStd, uint256 quantityLrg, uint256 quantityPrm, bool stake, bool bundle) internal {
        uint256 priceReduction;
        if (bundle) {
          require(bundleCurrentSupply < maxBundles, "T8");
          require(quantityStd == 1 && quantityLrg == 1 && quantityPrm == 1, "T14");
          priceReduction = 0.05 ether;
          bundleCurrentSupply += 1;
        }
        require(
            msg.value ==
                priceStd *
                quantityStd +
                priceLrg *
                quantityLrg +
                pricePrm *
                quantityPrm -
                priceReduction,
            "T2"
        );
        require(quantityStd <= MAX_MINT_STD && quantityLrg <= MAX_MINT_LRG && quantityPrm <= MAX_MINT_PRM, "T5");


      require(
          standardCurrentSupply + quantityStd <= standardMaxSupply &&
              largeCurrentSupply + quantityLrg <= largeMaxSupply &&
              premiumCurrentSupply + quantityPrm <= premiumMaxSupply,
          "T4"
      );

      standardCurrentSupply += quantityStd;
      largeCurrentSupply += quantityLrg;
      premiumCurrentSupply += quantityPrm;

      if (stake) {
        mintAndStake(quantityStd, quantityLrg, quantityPrm);
      } else {
        mint(quantityStd, quantityLrg, quantityPrm);
      }
    }

    /*
     * mint tokens and set their types
     *
     * @param quantityStd: standard tokens quantity
     * @param quantityLrg: large tokens quantity
     * @param quantityPrm: premium tokens quantity
     */
    function mint(uint256 quantityStd, uint256 quantityLrg, uint256 quantityPrm) internal {

      for (uint256 index = 1; index <= quantityStd + quantityLrg + quantityPrm; index++) {
          if (index <= quantityPrm) {
            tokenType[totalSupply() + index] = 2;
          } else if (index <= quantityPrm + quantityLrg) {
            tokenType[totalSupply() + index] = 1;
          }
          // else token type is already 0
      }

      _safeMint(msg.sender, quantityStd + quantityLrg + quantityPrm);
    }

    /*
     * mint tokens, set their types and stake them
     *
     * @param quantityStd: standard tokens quantity
     * @param quantityLrg: large tokens quantity
     * @param quantityPrm: premium tokens quantity
     */
    function mintAndStake(uint256 quantityStd, uint256 quantityLrg, uint256 quantityPrm) internal {
      uint256 currTotalSupply = totalSupply();
      _safeMint(address(staking), quantityStd + quantityLrg + quantityPrm); // mint to staking directly

      for (uint256 index = 1; index <= quantityStd + quantityLrg + quantityPrm; index++) {
          if (index <= quantityPrm) {
            tokenType[currTotalSupply + index] = 2;
          } else if (index <= quantityPrm + quantityLrg) {
            tokenType[currTotalSupply + index] = 1;
          }
          // else token type is already 0

          staking.stakeFromNFTContract(currTotalSupply + index); // stake nft directly
      }
    }

    /*
     * Airdrop tokens to address
     *
     * @param to: recipient of the tokens
     * @param quantityStd: standard tokens quantity
     * @param quantityLrg: large tokens quantity
     * @param quantityPrm: premium tokens quantity
     *
     * Error messages:
     *  - T4: "Collection's max supply reached"
     *  - T5: "Max quantity per transaction reached"
     */
    function airdrop(
        address to,
        uint256 quantityStd,
        uint256 quantityLrg,
        uint256 quantityPrm
    ) external onlyOwner {
      require(quantityStd + quantityLrg + quantityPrm <= 15, "T5");

      require(
          standardCurrentSupply + quantityStd <= standardMaxSupply &&
              largeCurrentSupply + quantityLrg <= largeMaxSupply &&
              premiumCurrentSupply + quantityPrm <= premiumMaxSupply,
          "T4"
      );

      standardCurrentSupply += quantityStd;
      largeCurrentSupply += quantityLrg;
      premiumCurrentSupply += quantityPrm;

      for (uint256 index = 1; index <= quantityStd + quantityLrg + quantityPrm; index++) {
          if (index <= quantityPrm) {
            tokenType[totalSupply() + index] = 2;
          } else if (index <= quantityPrm + quantityLrg) {
            tokenType[totalSupply() + index] = 1;
          }
          // else token type is already 0
      }

      _safeMint(to, quantityStd + quantityLrg + quantityPrm);
    }

    /*
     * freemint tokens to address
     *
     * @param quantityStd: standard tokens quantity
     * @param quantityLrg: large tokens quantity
     * @param quantityPrm: premium tokens quantity
     * @param signature: admin signture to allow minting
     *
     * Error messages:
     *  - T4: "Collection's max supply reached"
     *  - T5: "Max quantity per transaction reached"
     */
    function freeMint(
        uint256 quantityStd,
        uint256 quantityLrg,
        uint256 quantityPrm,
        bytes calldata signature
    ) external {
      require(quantityStd + quantityLrg + quantityPrm <= 15, "T5");

      require(
          standardCurrentSupply + quantityStd <= standardMaxSupply &&
              largeCurrentSupply + quantityLrg <= largeMaxSupply &&
              premiumCurrentSupply + quantityPrm <= premiumMaxSupply,
          "T4"
      );

      standardCurrentSupply += quantityStd;
      largeCurrentSupply += quantityLrg;
      premiumCurrentSupply += quantityPrm;

      // check signature
      uint256 nonce = nonces[msg.sender] + 1;
      require(hasRole(SIGNER_ROLE, ECDSALibrary.recover(abi.encodePacked(msg.sender, quantityStd, quantityLrg, quantityPrm, nonce), signature)), "N6");
      nonces[msg.sender] += 1;

      mint(quantityStd, quantityLrg, quantityPrm);
    }

    /*
     * Burn a token from the previous launch and claim the same tokenId on the new collection
     *
     * @param tokenId: tokenId of the island
     *
     * Error messages:
     *  - T16: "You don't own this token"
     *  - T17: "That NFT was already claimed"
     */
    function bridgeTokens(uint256 tokenId) external {
        require(previousLaunch.ownerOf(tokenId) == msg.sender, "T16");
        require(ownerOf(tokenId) == address(this), "T17");
        previousLaunch.transferFrom(msg.sender, address(this), tokenId);
        ITheNFTIslands(this).transferFrom(address(this), msg.sender, tokenId);

        tokenType[tokenId] = previousLaunch.getTokenType(tokenId);

        tokenContract.transfer(msg.sender, 5000 ether);
    }

    /*
     * get the island's size
     *
     * @param tokenId: tokenId of the island
     *
     * Error messages:
     *  - I10: "tokenId doesn't exist"
     */
    function getTokenType(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        require(_exists(tokenId), "T10");
        return tokenType[tokenId];
    }

    /*
     * override of the baseURI to use private variable _baseTokenURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /*
     * change base URI of tokens
     *
     * Error messages:
     * - T15 : "URI has been frozen"
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        require(!isUriFrozen, "T15");
        _baseTokenURI = baseURI;
    }

    /*
     * freezes uri of tokens
     *
     * Error messages:
     * - T18 : "URI already frozen"
     */
    function freezeMetadata() external onlyOwner {
        require(!isUriFrozen, "T18");
        isUriFrozen = true;
    }

    /**
     * Contract level Metadata URI
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, "collection"));
    }

    /**
     * overrides start tokenId
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * Withdraw contract's funds
     *
     * Error messages:
     * - T11 : "No shares for this account"
     * - T12 : "No remaining payment"
     */
    function withdraw(address account) external {
        require(shares[account] > 0, "T11");

        uint256 totalReceived = address(this).balance + totalReleased;
        uint256 payment = (totalReceived * shares[account]) /
            totalShares -
            released[account];

        released[account] = released[account] + payment;
        totalReleased = totalReleased + payment;

        require(payment > 0, "T12");

        payable(account).transfer(payment);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC721A, ERC721A, AccessControl) returns (bool) {
      return
      interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
      interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
      interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
      interfaceId == type(IAccessControl).interfaceId;
    }
}