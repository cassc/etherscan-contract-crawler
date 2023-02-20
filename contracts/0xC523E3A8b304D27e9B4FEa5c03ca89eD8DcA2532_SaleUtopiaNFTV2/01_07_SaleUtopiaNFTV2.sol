// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./AggregatorV3Interface.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721Receiver.sol";
import "./MerkleProof.sol";

interface IUtopia {
    function mint(address to, uint256 qty) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract SaleUtopiaNFTV2 is Ownable, ReentrancyGuard, IERC721Receiver {
    // treasuryAddr
    address public treasuryAddr;
    // Utopia SC collection
    IUtopia public immutable utopia;
    // Price Feed
    AggregatorV3Interface public priceFeed;
    // Current Phase
    uint8 public currentPhaseId;
    // Info of each phase.
    struct PhaseInfo {
        uint256 priceInUSDPerNFT;
        uint256 priceInUSDPerNFTWithoutWhiteList;
        uint256 maxTotalSales;
        uint256 maxSalesPerWallet;
        bool whiteListRequired;
        bool phasePriceInUSD;
        uint256 priceInWeiPerNFT;
        uint256 priceInWeiPerNFTWithoutWhiteList;
    }
    // Phases Info
    PhaseInfo[] public phasesInfo;
    // Phases Total Sales
    mapping(uint256 => uint256) public phasesTotalSales;
    // Phases Wallet Sales
    mapping(uint256 => mapping(address => uint256)) public phasesWalletSales;
    // AllowList
    bytes32 public allowlistMerkleRoot;
    // AllowedToBuyWithCreditCard
    mapping(address => bool) public allowedToBuyWithCreditCard;

    event AddPhase(uint256 indexed _priceInUSDPerNFT, uint256 indexed _priceInUSDPerNFTWithoutWhiteList, uint256 _maxTotalSales, uint256 _maxSalesPerWallet, bool _whiteListRequired, bool _phasePriceInUSD, uint256 _priceInWeiPerNFT, uint256 _priceInWeiPerNFTWithoutWhiteList);
    event EditPhase(uint8 indexed _phaseId, uint256 indexed _priceInUSDPerNFT, uint256 _priceInUSDPerNFTWithoutWhiteList, uint256 _maxTotalSales, uint256 _maxSalesPerWallet, bool _whiteListRequired, bool _phasePriceInUSD, uint256 _priceInWeiPerNFT, uint256 _priceInWeiPerNFTWithoutWhiteList);
    event ChangeCurrentPhase(uint8 indexed _phaseId);
    event ChangePriceFeedAddress(address indexed _priceFeedAddress);
    event Buy(uint256 indexed quantity, address indexed to);
    event BuyWithCreditCard(uint256 indexed quantity, address indexed to);
    event SetAllowlistMerkleRoot(bytes32 indexed _allowlistMerkleRoot);
    event SetTreasury(address indexed _treasuryAddr);
    event WithdrawMoney();
    event SetAddressToBuyWithCreditCardAllowed(address indexed _account, bool indexed _canBuy);

    modifier onlyAllowListed(bytes32[] calldata _merkleProof, address _to) {
        PhaseInfo storage phase = phasesInfo[currentPhaseId];

        if (phase.whiteListRequired) {
            require(_to == msg.sender, "In this phase it is mandatory that you can only mint to your own wallet");
            bool passMerkle = checkMerkleProof(_merkleProof, _to);
            require(passMerkle, "Not allowListed");
        }
        _;
    }

    modifier onlyBuyWithCreditCardAllowedUsers() {
        require(allowedToBuyWithCreditCard[msg.sender], "You can't buy with credit card ;)");
        _;
    }

    constructor(
        IUtopia _utopia,
        address _treasuryAddr,
        address _priceFeedAddress,
        uint8 _currentPhaseId
    ) {
        require(address(_utopia) != address(0));
        require(_treasuryAddr != address(0));
        require(_priceFeedAddress != address(0));

        utopia = _utopia;
        treasuryAddr = _treasuryAddr;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        currentPhaseId = _currentPhaseId;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function phasesInfoLength() public view returns (uint256) {
        return phasesInfo.length;
    }

    function checkMerkleProof(bytes32[] calldata _merkleProof, address _to) public view virtual returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_to));
        return MerkleProof.verify(_merkleProof, allowlistMerkleRoot, leaf);
    }

    function setCurrentPhase(uint8 _currentPhaseId) external onlyOwner {
        require(_currentPhaseId < phasesInfoLength(), "you cannot activate a phase that does not yet exist");
        currentPhaseId = _currentPhaseId;
        emit ChangeCurrentPhase(_currentPhaseId);
    }

    function changePriceFeedAddress(address _priceFeedAddress) external onlyOwner {
        require(_priceFeedAddress != address(0));
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        emit ChangePriceFeedAddress(_priceFeedAddress);
    }

    function addPhase(uint256 _priceInUSDPerNFT, uint256 _priceInUSDPerNFTWithoutWhiteList, uint256 _maxTotalSales, uint256 _maxSalesPerWallet, bool _whiteListRequired, bool _phasePriceInUSD, uint256 _priceInWeiPerNFT, uint256 _priceInWeiPerNFTWithoutWhiteList) external onlyOwner {
        phasesInfo.push(PhaseInfo({
            priceInUSDPerNFT: _priceInUSDPerNFT,
            priceInUSDPerNFTWithoutWhiteList: _priceInUSDPerNFTWithoutWhiteList,
            maxTotalSales: _maxTotalSales,
            maxSalesPerWallet: _maxSalesPerWallet,
            whiteListRequired: _whiteListRequired,
            phasePriceInUSD: _phasePriceInUSD,
            priceInWeiPerNFT: _priceInWeiPerNFT,
            priceInWeiPerNFTWithoutWhiteList: _priceInWeiPerNFTWithoutWhiteList
        }));

        emit AddPhase(_priceInUSDPerNFT, _priceInUSDPerNFTWithoutWhiteList, _maxTotalSales, _maxSalesPerWallet, _whiteListRequired, _phasePriceInUSD, _priceInWeiPerNFT, _priceInWeiPerNFTWithoutWhiteList);
    }

    function editPhase(uint8 _phaseId, uint256 _priceInUSDPerNFT, uint256 _priceInUSDPerNFTWithoutWhiteList, uint256 _maxTotalSales, uint256 _maxSalesPerWallet, bool _whiteListRequired, bool _phasePriceInUSD, uint256 _priceInWeiPerNFT, uint256 _priceInWeiPerNFTWithoutWhiteList) external onlyOwner {
        require(_phaseId < phasesInfoLength(), "you cannot edit a phase that does not exist");
        require(phasesInfo[_phaseId].priceInUSDPerNFT >= _priceInUSDPerNFT, "Utopia:priceInUSDPerNFT: the price must be equal to or below the previous price");
        require(phasesInfo[_phaseId].priceInUSDPerNFTWithoutWhiteList >= _priceInUSDPerNFTWithoutWhiteList, "Utopia:priceInUSDPerNFTWithoutWhiteList: the price must be equal to or below the previous price");
        require(phasesInfo[_phaseId].priceInWeiPerNFT >= _priceInWeiPerNFT, "Utopia:priceInWeiPerNFT: the price must be equal to or below the previous price");
        require(phasesInfo[_phaseId].priceInWeiPerNFTWithoutWhiteList >= _priceInWeiPerNFTWithoutWhiteList, "Utopia:priceInWeiPerNFTWithoutWhiteList: the price must be equal to or below the previous price");

        phasesInfo[_phaseId].priceInUSDPerNFT = _priceInUSDPerNFT;
        phasesInfo[_phaseId].priceInUSDPerNFTWithoutWhiteList = _priceInUSDPerNFTWithoutWhiteList;
        phasesInfo[_phaseId].maxTotalSales = _maxTotalSales;
        phasesInfo[_phaseId].maxSalesPerWallet = _maxSalesPerWallet;
        phasesInfo[_phaseId].whiteListRequired = _whiteListRequired;
        phasesInfo[_phaseId].phasePriceInUSD = _phasePriceInUSD;
        phasesInfo[_phaseId].priceInWeiPerNFT = _priceInWeiPerNFT;
        phasesInfo[_phaseId].priceInWeiPerNFTWithoutWhiteList = _priceInWeiPerNFTWithoutWhiteList;

        emit EditPhase(_phaseId, _priceInUSDPerNFT, _priceInUSDPerNFTWithoutWhiteList, _maxTotalSales, _maxSalesPerWallet, _whiteListRequired, _phasePriceInUSD, _priceInWeiPerNFT, _priceInWeiPerNFTWithoutWhiteList);
    }

    function getLatestPrice() public view returns (int) {
        (
            ,
            int price,
            ,
            ,

        ) = priceFeed.latestRoundData();

        return (
            price
        );
    }

    function setAllowlistMerkleRoot(bytes32 _allowlistMerkleRoot) external onlyOwner {
        allowlistMerkleRoot = _allowlistMerkleRoot;
        emit SetAllowlistMerkleRoot(_allowlistMerkleRoot);
    }

    function setAddressToBuyWithCreditCardAllowed(address _account, bool _canBuy) external onlyOwner {
        allowedToBuyWithCreditCard[_account] = _canBuy;
        emit SetAddressToBuyWithCreditCardAllowed(_account, _canBuy);
    }

    function setTreasury(address _treasuryAddr) external onlyOwner {
        treasuryAddr = _treasuryAddr;
        emit SetTreasury(_treasuryAddr);
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = treasuryAddr.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
        emit WithdrawMoney();
    }

    function transferGuardedNfts(uint256[] memory tokensId, address[] memory addresses) external onlyOwner
    {
        require(
            addresses.length == tokensId.length,
            "addresses does not match tokensId length"
        );

        for (uint256 i = 0; i < addresses.length; ++i) {
            utopia.transferFrom(address(this), addresses[i], tokensId[i]);
        }
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external virtual onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    function recoverERC721TransferFrom(address nftAddress, address to, uint256 tokenId) external virtual onlyOwner {
        IERC721(nftAddress).transferFrom(address(this), to, tokenId);
    }

    function buyWithCreditCard(uint256 _quantity, address _to) external onlyBuyWithCreditCardAllowedUsers nonReentrant {
        PhaseInfo storage phase = phasesInfo[currentPhaseId];

        require(phase.maxTotalSales >= phasesTotalSales[currentPhaseId] + _quantity, "this phase does not allow this purchase");

        phasesTotalSales[currentPhaseId] = phasesTotalSales[currentPhaseId] + _quantity;

        utopia.mint(_to, _quantity);

        emit BuyWithCreditCard(_quantity, _to);
    }

    function buy(uint256 _quantity, address _to, bytes32[] calldata _merkleProof) external payable nonReentrant onlyAllowListed(_merkleProof, _to) {
        uint256 totalPrice;
        uint256 priceInUSD;
        uint256 priceInWei;

        require(phasesInfo[currentPhaseId].maxTotalSales >= phasesTotalSales[currentPhaseId] + _quantity, "this phase does not allow this purchase");
        require(phasesInfo[currentPhaseId].maxSalesPerWallet >= phasesWalletSales[currentPhaseId][_to] + _quantity, "you can not buy as many NFTs in this phase");

        if (checkMerkleProof(_merkleProof, _to)) {
            priceInUSD = phasesInfo[currentPhaseId].priceInUSDPerNFT;
            priceInWei = phasesInfo[currentPhaseId].priceInWeiPerNFT;
        } else {
            priceInUSD = phasesInfo[currentPhaseId].priceInUSDPerNFTWithoutWhiteList;
            priceInWei = phasesInfo[currentPhaseId].priceInWeiPerNFTWithoutWhiteList;
        }

        if (phasesInfo[currentPhaseId].phasePriceInUSD) {
            uint256 totalPriceInUSD = priceInUSD * _quantity * 1e8 * 1e18;

            (
            int ethPrice
            ) = getLatestPrice();

            uint256 ethPrice256 = uint256(ethPrice);
            totalPrice = (totalPriceInUSD * 1e24) / (ethPrice256 * 1e24);
        } else {
            totalPrice = priceInWei * _quantity;
        }

        phasesTotalSales[currentPhaseId] = phasesTotalSales[currentPhaseId] + _quantity;
        phasesWalletSales[currentPhaseId][_to] = phasesWalletSales[currentPhaseId][_to] + _quantity;

        refundIfOver(totalPrice);
        (bool success, ) = treasuryAddr.call{value: address(this).balance}("");
        require(success);
        utopia.mint(_to, _quantity);

        emit Buy(_quantity, _to);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            (bool success, ) = msg.sender.call{value: msg.value - price}("");
            require(success);
        }
    }

}