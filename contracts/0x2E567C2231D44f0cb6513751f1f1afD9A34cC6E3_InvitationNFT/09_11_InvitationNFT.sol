// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract InvitationNFT is ERC721A, Ownable {
    enum SaleType {
        WL_MINT,
        PUBLIC_MINT,
        SS_SALE,
        YUGA_LABS,
        AIRDROP_MINT
    }

    // Payment beneficiary accounts
    address payable public beneficiary;

    // BAGC
    address public bagcAddress;

    string public baseURI;
    bytes32 public merkleRootWLMint;
    bytes32 public merkleRootSSSale;

    uint256 public apePriceFeed = 336; // 1 eth = 336 Ape
    uint256 public tavaPriceFeed = 4_241; // 1 eth = 4438 Tava
    uint256 public maxTokens = 9_000;
    uint256 public maxMintLimit = 3;

    // ERC20 Payment Parameters
    address public apeTokenAddress = 0x4d224452801ACEd8B2F0aebE155379bb5D594381;
    address public tavaTokenAddress = 0xdebe620609674F21B1089042527F420372eA98A5;

    // ERC721 Holders Tokens
    address public constant SSContractAddress = 0x82f371b47cc5B9Cf23Af60A9A31A9E7A6bef8A2d;
    address public constant BAYCContractAddress = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address public constant MAYCContractAddress = 0x60E4d786628Fea6478F785A6d7e704777c86a7c6;
    address public constant BAKCContractAddress = 0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623;

    mapping(SaleType => uint256) public mSaleTypeToBasePrice;
    mapping(SaleType => uint256) public mSaleTypeToDiscountPrice;
    mapping(SaleType => uint256) public mSaleTypeToOpenTime;
    mapping(SaleType => uint256) public mSaleTypeToCloseTime;
    mapping(SaleType => uint256) public mSaleTypeToMintQuantityLimit;
    mapping(SaleType => uint256) public mSaleTypeToMintCount;
    mapping(address => uint256) public mAddressToSSSaleMintCount;
    mapping(address => uint256) public mAddressToYugaLabsMintCount;

    modifier checkSaleTime(SaleType t) {
        require(block.timestamp >= mSaleTypeToOpenTime[t], "Sale is not open");
        require(block.timestamp <= mSaleTypeToCloseTime[t], "Sale is not open");
        _;
    }

    modifier checkRemainQuantity(SaleType t, uint256 quantity) {
        require(_totalMinted() + quantity <= maxTokens, "All NFTs are minted");
        require(
            mSaleTypeToMintCount[t] + quantity <= mSaleTypeToMintQuantityLimit[t],
            "All NFT are minted for SaleType"
        );
        _;
    }

    modifier checkValidity(bytes32[] calldata _merkleProof, bytes32 merkleRoot) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Incorrect proof");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address payable beneficiary_
    ) ERC721A(name_, symbol_) {
        baseURI = baseURI_;
        beneficiary = beneficiary_;

        SaleType t = SaleType.WL_MINT;
        mSaleTypeToMintQuantityLimit[t] = 810;
        mSaleTypeToBasePrice[t] = 0.45 ether; // 0.45 eth
        mSaleTypeToDiscountPrice[t] = 0.4 ether; // 0.4 eth
        mSaleTypeToOpenTime[t] = 1671541200; // Dec 20, 22:00(KST)
        mSaleTypeToCloseTime[t] = 1671627600; // Dec 21, 22:00(KST)

        t = SaleType.PUBLIC_MINT;
        mSaleTypeToMintQuantityLimit[t] = 500;
        mSaleTypeToBasePrice[t] = 0.5 ether;
        mSaleTypeToDiscountPrice[t] = 0.45 ether;
        mSaleTypeToOpenTime[t] = 1671627600; // Dec 21, 22:00(KST)
        mSaleTypeToCloseTime[t] = 1671714000; // Dec 22, 22:00(KST)

        t = SaleType.SS_SALE;
        mSaleTypeToMintQuantityLimit[t] = 1_500;
        mSaleTypeToBasePrice[t] = 0.425 ether;
        mSaleTypeToDiscountPrice[t] = 0.375 ether;
        mSaleTypeToOpenTime[t] = 1671714000; // Dec 22, 22:00(KST)
        mSaleTypeToCloseTime[t] = 1671800400; // Dec 23, 22:00(KST)

        t = SaleType.YUGA_LABS;
        mSaleTypeToMintQuantityLimit[t] = 2_000;
        mSaleTypeToBasePrice[t] = 0.425 ether;
        mSaleTypeToDiscountPrice[t] = 0.425 ether;
        mSaleTypeToOpenTime[t] = 1671800400; // Dec 23, 22:00(KST)
        mSaleTypeToCloseTime[t] = 1679576400; // Mar 23, 22:00(KST)

        t = SaleType.AIRDROP_MINT;
        mSaleTypeToMintQuantityLimit[t] = 4_190; //1_000 + 2_000 + 500 + 690;
        mSaleTypeToBasePrice[t] = 0 ether;
        mSaleTypeToDiscountPrice[t] = 0 ether;
        mSaleTypeToOpenTime[t] = 0; // Always open
        mSaleTypeToCloseTime[t] = 1679576400; // Mar 23, 22:00(KST)
    }

    function withdrawETH(address payable to, uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Over balance");
        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed withdraw ETH");
    }

    function withdrawToken(
        address payable to,
        address tokenAddress,
        uint256 amount
    ) public onlyOwner {
        IERC20 paymentToken = IERC20(tokenAddress);
        bool status = paymentToken.transferFrom(address(this), to, amount);
        require(status, "Failed withdraw ERC20");
    }

    function updateBagcAddress(address bagcAddress_) public onlyOwner {
        bagcAddress = bagcAddress_;
    }

    function updateBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function updateSaleTime(
        SaleType t,
        uint256 openTime_,
        uint256 closeTime_
    ) public onlyOwner {
        mSaleTypeToOpenTime[t] = openTime_;
        mSaleTypeToCloseTime[t] = closeTime_;
    }

    function updateBeneficiaryAddress(address payable beneficiary_) public onlyOwner {
        beneficiary = beneficiary_;
    }

    function updateMerkleRoot(SaleType t, bytes32 root) public onlyOwner {
        if (t == SaleType.WL_MINT) {
            merkleRootWLMint = root;
        } else if (t == SaleType.SS_SALE) {
            merkleRootSSSale = root;
        }
    }

    // maxMintLimit is only for WLSaleMint
    function updateMaxMintLimit(uint256 maxMintLimit_) public onlyOwner {
        maxMintLimit = maxMintLimit_;
    }

    // totalNumber of avaiable InvitationNFT
    function updateMaxToken(uint256 maxTokens_) public onlyOwner {
        maxTokens = maxTokens_;
    }

    function updateBasePrice(SaleType t, uint256 price) public onlyOwner {
        require(price > 0);
        mSaleTypeToBasePrice[t] = price;
    }

    function updateDiscountPrice(SaleType t, uint256 price) public onlyOwner {
        require(price > 0);
        mSaleTypeToDiscountPrice[t] = price;
    }

    function updateMintQuantityLimit(SaleType t, uint256 mintQuantityLimit_) public onlyOwner {
        mSaleTypeToMintQuantityLimit[t] = mintQuantityLimit_;
    }

    function updateApeTokenAddress(address tokenAddress) public onlyOwner {
        apeTokenAddress = tokenAddress;
    }

    function updateTavaTokenAddress(address tokenAddress) public onlyOwner {
        tavaTokenAddress = tokenAddress;
    }

    function updateApePriceFeed(uint256 price_) public onlyOwner {
        require(price_ > 0);
        apePriceFeed = price_;
    }

    function updateTavaPriceFeed(uint256 price_) public onlyOwner {
        require(price_ > 0);
        tavaPriceFeed = price_;
    }

    function updatePriceFeeds(uint256 apePriceFeed_, uint256 tavaPriceFeed_) public onlyOwner {
        require(apePriceFeed_ > 0 && tavaPriceFeed_ > 0);
        apePriceFeed = apePriceFeed_;
        tavaPriceFeed = tavaPriceFeed_;
    }

    function WlMintBAGC(uint256 quantity, bytes32[] calldata merkleProof)
        public
        payable
        checkSaleTime(SaleType.WL_MINT)
        checkRemainQuantity(SaleType.WL_MINT, quantity)
        checkValidity(merkleProof, merkleRootWLMint)
    {
        require(quantity <= maxMintLimit, "Over Mint Limit");
        SaleType t = SaleType.WL_MINT;

        pay(t, quantity);
        addMintCount(t, quantity);
        _safeMint(msg.sender, quantity);
    }

    function publicSaleMint(uint256 quantity)
        public
        payable
        checkSaleTime(SaleType.PUBLIC_MINT)
        checkRemainQuantity(SaleType.PUBLIC_MINT, quantity)
    {
        require(quantity <= maxMintLimit, "Over Mint Limit");
        SaleType t = SaleType.PUBLIC_MINT;

        pay(t, quantity);
        addMintCount(t, quantity);
        _safeMint(msg.sender, quantity);
    }

    function SSSaleMint(uint256 quantity, bytes32[] calldata merkleProof)
        public
        payable
        checkSaleTime(SaleType.SS_SALE)
        checkRemainQuantity(SaleType.SS_SALE, quantity)
        checkValidity(merkleProof, merkleRootSSSale)
    {
        SaleType t = SaleType.SS_SALE;

        pay(t, quantity);
        addMintCount(t, quantity);
        _safeMint(msg.sender, quantity);
        mAddressToSSSaleMintCount[msg.sender] += quantity;
    }

    function YugaLabsMint(uint256 quantity)
        public
        payable
        checkSaleTime(SaleType.YUGA_LABS)
        checkRemainQuantity(SaleType.YUGA_LABS, quantity)
    {
        SaleType t = SaleType.YUGA_LABS;

        //check YugaLabs holder balance
        uint256 YugaLabsTokenBalance = getHolderNFTBalance(t);
        require(YugaLabsTokenBalance > 0, "0 NFT Balance");
        require(mAddressToYugaLabsMintCount[msg.sender] + quantity <= YugaLabsTokenBalance);

        pay(t, quantity);
        addMintCount(t, quantity);
        _safeMint(msg.sender, quantity);
        mAddressToYugaLabsMintCount[msg.sender] += quantity;
    }

    function AirDropMint(address to, uint256 quantity)
        public
        checkSaleTime(SaleType.AIRDROP_MINT)
        checkRemainQuantity(SaleType.AIRDROP_MINT, quantity)
        onlyOwner
    {
        addMintCount(SaleType.AIRDROP_MINT, quantity);
        _safeMint(to, quantity);
    }

    function burn(uint256 tokenId) external {
        require(bagcAddress == msg.sender, "Wrong Contract");
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _startTokenId() internal pure override returns (uint256 startTokenId) {
        startTokenId = 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function addMintCount(SaleType t, uint256 quantity) internal {
        mSaleTypeToMintCount[t] += quantity;
    }

    function getHolderNFTBalance(SaleType t) internal view returns (uint256 tokenBalance) {
        if (t == SaleType.SS_SALE) {
            IERC721 SSContract = IERC721(SSContractAddress);
            tokenBalance = SSContract.balanceOf(msg.sender);
        } else if (t == SaleType.YUGA_LABS) {
            IERC721 BAYCContract = IERC721(BAYCContractAddress);
            IERC721 MAYCContract = IERC721(MAYCContractAddress);
            IERC721 BAKCContract = IERC721(BAKCContractAddress);
            tokenBalance =
                BAYCContract.balanceOf(msg.sender) +
                MAYCContract.balanceOf(msg.sender) +
                BAKCContract.balanceOf(msg.sender);
        }
    }

    function pay(SaleType t, uint256 quantity) internal {
        if (msg.value != 0) {
            // PAY with Eth
            uint256 price = mSaleTypeToBasePrice[t] * quantity;
            require(msg.value >= price, "We require more ether"); // validate the amount of ETH
            uint256 leftOver = msg.value - price;
            (bool success, ) = beneficiary.call{value: price}(""); // send ETH to the owner
            require(success, "Failed to send Ether");
            if (leftOver > 0) {
                payable(msg.sender).transfer(leftOver);
            }
        } else {
            // PAY with Special Token
            bool status = false;
            uint256 price = mSaleTypeToDiscountPrice[t] * quantity;
            address paymentTokenAddress;
            if (t == SaleType.YUGA_LABS) {
                // Pay with APE
                price = price * apePriceFeed;
                paymentTokenAddress = apeTokenAddress;
            } else {
                // Pay with TAVA
                price = price * tavaPriceFeed;
                paymentTokenAddress = tavaTokenAddress;
            }
            IERC20 paymentToken = IERC20(paymentTokenAddress);
            status = paymentToken.transferFrom(msg.sender, beneficiary, price);

            require(status, "Failed to send Token");
        }
    }
}