//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract NANOCATS is ERC1155Supply, Ownable, ReentrancyGuard, IERC2981 {
    using Strings for uint256;

    bool public transferActive = false;
    bool public mintActive = false;  

    uint8 public seasonNumber = 0;      // Seasons start at # 1
    uint8 private constant NV1_id = 1;  // first of two types
    uint8 private constant NV2_id = 2;  // second of two types
    uint8 private constant mintBatchLimit = 5;  // limit of how many NV2s can be minted in a single transaction
    uint16 public constant NV1_SALE_SUPPLY = 12095; // Max number of NV1s that can be minted
    uint16 public constant NV1_RESERVE = 405; // Reserved NV1s for the team
                                                // Total NV1 will be 12500
    bool private nv1ReserveMinted = false;
    bool private nv2ReserveMinted = false;

    uint16 public NV2_SEASON_SUPPLY; // Max number of NV2s that can be minted in a season
    uint16 public NV2_SEASON_RESERVE; // Max number of NV2s that can be minted in a season
    uint16 public NV2_SEASON_MINTED; // Total number of NV2s minted so far in the season

    uint16 internal royalty = 1000; // base 10000, 10%
    uint16 public constant SPLIT_BASE = 10000;
    uint16 public constant BASE = 10000;
    uint32 public redeemStart;              // May 27, 2022 1pm EST
    uint32 public redeemEnd;                // May 27, 2022 11pm EST
    string public symbol;                   // NCAT
    string public name;                     // NANOCATS
    string public uriPrefix;
    string public uriSuffix;
    string private contractMetadata = 'contract.json';

    struct SeasonDate {
        uint32 seasonPrivateSaleStart;
        uint32 seasonPrivateSaleEnd;
        uint32 seasonPublicSaleStart;
        uint32 seasonPublicSaleEnd;
    }

    SeasonDate public seasonDates;

    // [12,30,245,270,526,607,778,780,917,966,1262,1849,2138,2457,2491,2506,2546,2599,2700,2706,2744,2877,2968,3195,3249,3316,3382,3410,3440,3538,3639,3682,3776,3790,3823,4020,4363,4745,4747,4748,4787,4911,5766,5770,6203,6263,6386,6389,6446,6534,6560,7005,7376,7395,8110,8439,8720,8772,8787,8807,8817,8862,8865,8869,8886,8940,8976,9145,9207,9255,9421,9431,9450,9472,9511,9642,9654,9849,9963,10023,10110,10138,10380,10432,10546,10723,10809,10845,11042,11231,11353,11754,11823,11940,11979];

    bool[12000] private mintedCBOT;  // To keep track of Catbots used to mint NV2

    bool[12000] private redeemedCBOT;  // To keep track of Catbots used to redeem NV1

	uint256 public constant NV2_PRIVATE_PRICE = 60000000000000000;	// 0.06 ETH 
    uint256 public constant NV2_PUBLIC_PRICE = 80000000000000000;   // 0.08 ETH 

    address[] private recipients;
    uint16[] private splits;

    mapping(address => bool) public proxyRegistryAddress;

    mapping(uint16 => bool) public bonusCBOT;

    mapping(address => bool) public approvedBurnAddress;

    IERC721 cbotContract;

    event NV1Redeem(address indexed owner, uint256[] ids);
    event NV2PrivateMint(address indexed owner, uint256[] ids);
    event NV2PublicMint(address indexed owner, uint256 amount);
    event ContractWithdraw(address indexed initiator, uint256 amount);
    event ContractWithdrawToken(address indexed initiator, address indexed token, uint256 amount);
    event WithdrawAddressChanged(address indexed previousAddress, address indexed newAddress);
    event SeasonDataUpdate(uint8 indexed season, uint32 seasonPrivateSaleStart, uint32 seasonPrivateSaleEnd, uint32 seasonPublicSaleStart, uint32 seasonPublicSaleEnd, uint16 nv2SeasonSupply, uint16 nv2SeasonReserve);

    constructor(
        string memory name_, 
        string memory symbol_, 
        string memory uriPrefix_, 
        string memory uriSuffix_, 
        address _cbotContract,
        address[] memory _recipients,
        uint16[] memory _splits,
        address _proxyAddress
    ) ERC1155(uriPrefix_) {
        name = name_;
        symbol = symbol_;
        uriPrefix = uriPrefix_;
        uriSuffix = uriSuffix_;
        cbotContract = IERC721(_cbotContract);
        recipients = _recipients;
        splits = _splits;
        proxyRegistryAddress[_proxyAddress] = true;
    }

    function setRedeemDates(uint32 _redeemStart, uint32 _redeemEnd) public onlyOwner {
        require(_redeemEnd > _redeemStart && uint256(_redeemStart) > block.timestamp ,'Invalid dates');
        redeemStart = _redeemStart;
        redeemEnd = _redeemEnd;
    }

    /// @dev start a new season and set the season supply
    /// @param _supply the season NV2 supply
    /// @param _seasonPrivateSaleStart season start date
    /// @param _seasonPrivateSaleEnd season end date
    /// @param _seasonPublicSaleStart season start date
    /// @param _seasonPublicSaleEnd season end date
    function newSeason(uint16 _supply, uint16 _reserve, uint32 _seasonPrivateSaleStart, uint32 _seasonPrivateSaleEnd, uint32 _seasonPublicSaleStart, uint32 _seasonPublicSaleEnd) public onlyOwner {
        require(uint256(_seasonPrivateSaleStart) > block.timestamp && block.timestamp > uint256(seasonDates.seasonPublicSaleEnd),'Season ongoing');
        seasonDates.seasonPrivateSaleStart = _seasonPrivateSaleStart;
        seasonDates.seasonPrivateSaleEnd = _seasonPrivateSaleEnd;
        seasonDates.seasonPublicSaleStart = _seasonPublicSaleStart;
        seasonDates.seasonPublicSaleEnd = _seasonPublicSaleEnd;
        seasonNumber++;
        delete mintedCBOT;
        nv2ReserveMinted = false;
        NV2_SEASON_SUPPLY = _supply;
        NV2_SEASON_RESERVE = _reserve;
        NV2_SEASON_MINTED = 0;
        emit SeasonDataUpdate(seasonNumber, _seasonPrivateSaleStart, _seasonPrivateSaleEnd, _seasonPublicSaleStart, _seasonPublicSaleEnd, NV2_SEASON_SUPPLY, NV2_SEASON_RESERVE);
    }
   
    function sendRedeem(address _account, uint256[] memory _ids) external onlyOwner {
        require(mintActive,'mint disabled');
        require(totalSupply(NV1_id) + _ids.length <= uint256(NV1_SALE_SUPPLY),'No more tokens');
        uint256 time = (block.timestamp);
        require(time > uint256(redeemStart) && time < uint256(redeemEnd), 'redeem not started');
        emit NV1Redeem(_account, _ids);
        for (uint16 i = 0; i < _ids.length; i++) {
            require(cbotContract.ownerOf(_ids[i]) == _account,'unauthorized');
            require(!redeemedCBOT[_ids[i] - 1],'Already redeemed');
            redeemedCBOT[_ids[i] - 1] = true;
            uint256 amount = 1;
            if(bonusCBOT[uint16(_ids[i])]) {
                amount = 2;
            }
            _mint(_account,NV1_id,amount,"");
        }
    }

    function setBounsIds(uint16[] memory _ids) public onlyOwner {
        for (uint16 i = 0; i < _ids.length; i++) {
            bonusCBOT[_ids[i]] = true;
        }
    }

    function mintNV1Reserve(address _account) external onlyOwner {
        require(!nv1ReserveMinted, 'already minted');
        uint256 time = (block.timestamp);
        require(time > uint256(redeemStart), 'Redeem not live');
        nv1ReserveMinted = true;
        _mint(_account,NV1_id,uint256(NV1_RESERVE),"");
    }

    function mintNV2Reserve(address _account) external onlyOwner {
        require(!nv2ReserveMinted, 'already minted');
        uint256 time = (block.timestamp);
        require(time > uint256(seasonDates.seasonPrivateSaleStart) && time < uint256(seasonDates.seasonPublicSaleStart), 'Sale not live');
        nv2ReserveMinted = true;
        NV2_SEASON_MINTED = NV2_SEASON_MINTED + NV2_SEASON_RESERVE;
        emit NV2PublicMint(_account, uint256(NV2_SEASON_RESERVE));
        _mint(_account,NV2_id,uint256(NV2_SEASON_RESERVE),"");
    }

    function mintPrivateSale(uint256[] memory _ids) external payable {
        require(mintActive,'mint disabled');
        require(NV2_SEASON_MINTED + _ids.length <= uint256(NV2_SEASON_SUPPLY - NV2_SEASON_RESERVE),'No more tokens');
        require(msg.value >= NV2_PRIVATE_PRICE * _ids.length, 'Insufficient ETH');
        uint256 time = (block.timestamp);
        require(time > uint256(seasonDates.seasonPrivateSaleStart) && time < uint256(seasonDates.seasonPrivateSaleEnd), 'Sale not live');
        emit NV2PrivateMint(msg.sender, _ids);
        for (uint16 i = 0; i < _ids.length; i++) {
            require(cbotContract.ownerOf(_ids[i]) == msg.sender,'unauthorized');
            require(!mintedCBOT[_ids[i] - 1],'token already used');
            mintedCBOT[_ids[i] - 1] = true;
            NV2_SEASON_MINTED++;
            _mint(msg.sender,NV2_id,1,"");
        }
    }

    function mintPublicSale(uint256 _amount) external payable {
        require(mintActive,'mint disabled');
        require(_amount > 0 && _amount <= uint256(mintBatchLimit), 'Batch limit is 5');
        require(NV2_SEASON_MINTED + _amount <= uint256(NV2_SEASON_SUPPLY),'No more tokens');
        require(msg.value >= NV2_PUBLIC_PRICE * _amount, 'Insufficient ETH');
        uint256 time = (block.timestamp);
        require(time > uint256(seasonDates.seasonPublicSaleStart) && time < uint256(seasonDates.seasonPublicSaleEnd), 'Sale not live');
        NV2_SEASON_MINTED = NV2_SEASON_MINTED + uint16(_amount);
        emit NV2PublicMint(msg.sender, _amount);
        _mint(msg.sender,NV2_id,_amount,"");
    }

    function flipMintActive() external onlyOwner {
        mintActive = !mintActive;
    }

    function flipTransferActive() external onlyOwner {
        transferActive = !transferActive;
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(exists(tokenId),'ERC1155Metadata: URI query for nonexistent token');
        return
            bytes(uriPrefix).length > 0
                ? string(abi.encodePacked(uriPrefix, tokenId.toString(), uriSuffix))
                : '';
    }
   
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(uriPrefix, contractMetadata));
    }

    function isMintedCBOT(uint256 _id) public view returns (bool) {
        return mintedCBOT[_id - 1];
    }

    function setBaseURI(string memory baseContractURI) external onlyOwner {
        uriPrefix = baseContractURI;
    }

    /**
    * @dev withdraws the contract balance and send it to the withdraw Addresses based on split ratio.
    *
    * Emits a {ContractWithdraw} event.
    */
    function withdraw() external nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < recipients.length; i++) {
        (bool sent, ) = payable(recipients[i]).call{value: (balance * splits[i]) / SPLIT_BASE}('');
        require(sent, 'Withdraw Failed.');
        }
        emit ContractWithdraw(msg.sender, balance);
    }

    /// @dev withdraw ERC20 tokens divided by splits
    function withdrawTokens(address _tokenContract) external nonReentrant onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        // transfer the token from address of Catbotica address
        uint256 balance = tokenContract.balanceOf(address(this));
        for (uint256 i = 0; i < recipients.length; i++) {
        tokenContract.transfer(recipients[i], (balance * splits[i]) / SPLIT_BASE);
        }
        emit ContractWithdrawToken(msg.sender, _tokenContract, balance);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function changeWithdrawAddress(address _recipient) external {
        require(_recipient != address(0), 'Cannot use zero address.');
        require(_recipient != address(this), 'Cannot use this contract address');
        require(!Address.isContract(_recipient), 'Cannot set recipient to a contract address');

        // loop over all the recipients and update the address
        bool _found = false;
        for (uint256 i = 0; i < recipients.length; i++) {
        // if the sender matches one of the recipients, update the address
        if (recipients[i] == msg.sender) {
            recipients[i] = _recipient;
            _found = true;
            break;
        }
        }
        require(_found, 'The sender is not a recipient.');
        emit WithdrawAddressChanged(msg.sender, _recipient);
    } 
   
    /// @notice Calculate the royalty payment
    /// @param _salePrice the sale price of the token
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (_salePrice * royalty) / BASE);
    }

    /// @dev set the royalty
    /// @param _royalty the royalty in base 10000, 500 = 5%
    function setRoyalty(uint16 _royalty) external virtual onlyOwner {
        require(_royalty >= 0 && _royalty <= 1000, 'Royalty must be between 0% and 10%.');

        royalty = _royalty;
    }
 
    /**
     * Function to allow receiving ETH sent to contract
     *
     */
    receive() external payable {}

    /**
     * Override isApprovedForAll to whitelisted marketplaces to enable gas-free listings.
     *
     */
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
        // check if this is an approved marketplace
        if (proxyRegistryAddress[_operator]) {
            return true;
        }
        // otherwise, use the default ERC721 isApprovedForAll()
        return super.isApprovedForAll(_owner, _operator);
    }

    /**
     * Function to set status of proxy contracts addresses
     *
     */
    function setProxy(address _proxyAddress, bool _value) external onlyOwner {
        proxyRegistryAddress[_proxyAddress] = _value;
    }

    function setApprovedBurningAddress(address _address, bool _status) external onlyOwner {
        approvedBurnAddress[_address] = _status;
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external {
        require(
            account == _msgSender() || approvedBurnAddress[_msgSender()] || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external {
        require(
            account == _msgSender() || approvedBurnAddress[_msgSender()] || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(transferActive || from == address(0),'ERC1155Pausable: token transfer while paused');
    }
}