// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IERC721 {
    function mint(address to, uint256 tokenId) external;
}

contract MonsterZoneLandPayment is AccessControl, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PRICE_UPDATER_ROLE = keccak256("PRICE_UPDATER_ROLE");

    IERC20 private TVK;
    IERC721 private NFT;

    uint256 private totalSupply;
    uint256 private cappedSupply;
    uint256 private slotCount;
    uint256 private TVKperUSDprice;
    uint256 private ETHperUSDprice;

    address private signatureAddress;
    address payable private withdrawAddress;

    bool private ethPaymentEnabled;
    bool private tvkPaymentEnabled;

    mapping(string => categoryDetail) private landCategory;
    mapping(uint256 => slotDetails) private slot;
    mapping(bytes => bool) private signatures;

    struct categoryDetail {
        uint256 priceInUSD;
        uint256 mintedCategorySupply;
        uint256 maxCategorySupply;
        uint256 startRange;
        uint256 endRange;
        bool status;
        bool slotIndependent;
    }

    struct slotDetails {
        uint256 startTime;
        uint256 endTime;
        mapping(string => slotCategoryDetails) slotSupply;
    }

    struct slotCategoryDetails {
        uint256 maxSlotCategorySupply;
        uint256 mintedSlotCategorySupply;
    }

    event landBoughtWithTVK(
        uint256 indexed tokenId,
        uint256 indexed price,
        address indexed beneficiary,
        string category,
        uint256 slot,
        bytes signature
    );

    event landBoughtWithETH(
        uint256 indexed tokenId,
        uint256 indexed price,
        address indexed beneficiary,
        string category,
        uint256 slot,
        bytes signature
    );

    event adminMintedItem(
        string category,
        uint256[] tokenId,
        address[] beneficiary
    );
    event newLandCategoryAdded(
        string indexed category,
        uint256 indexed price,
        uint256 indexed maxCategorySupply
    );
    event newSlotAdded(
        uint256 indexed slot,
        uint256 indexed startTime,
        uint256 indexed endTime,
        string[] category,
        uint256[] slotSupply
    );
    event TVKperUSDpriceUpdated(uint256 indexed price);
    event ETHperUSDpriceUpdated(uint256 indexed price);
    event landCategoryPriceUpdated(
        string indexed category,
        uint256 indexed price
    );
    event categoryAvailabilityInSlotUpdated(
        string indexed category,
        uint256 indexed slot,
        uint256 indexed slotSupply
    );
    event slotStartTimeUpdated(uint256 indexed slot, uint256 indexed startTime);
    event slotEndTimeUpdated(uint256 indexed slot, uint256 indexed endTime);
    event signatureAddressUpdated(address indexed newAddress);
    event TVKAddressUpdated(address indexed newAddress);
    event NFTAddressUpdated(address indexed newAddress);
    event withdrawAddressUpdated(address indexed newAddress);
    event ETHFundsWithdrawn(uint256 indexed amount);
    event TVKFundsWithdrawn(uint256 indexed amount);

    constructor(
        address _TVKaddress,
        address _NFTaddress,
        address payable _withdrawAddress,
        string[] memory _category,
        bool[] memory _slotDependency,
        uint256[][] memory _categoryDetail,
        uint256[][] memory _slot,
        uint256[][] memory _slotSupply
    ) {
        TVK = IERC20(_TVKaddress);
        NFT = IERC721(_NFTaddress);
        signatureAddress = 0xE3066b8a680B562Cc2B53f9542361078c666dE15;
        withdrawAddress = _withdrawAddress;
        TVKperUSDprice = 26470588235294116000; 
        ETHperUSDprice = 785064924869286; 
        cappedSupply = 6002;
        totalSupply = 0;
        ethPaymentEnabled = true;
        tvkPaymentEnabled = true;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, 0x6AB132Cf61F582535397fc7E36089DD49Fef5C59);
        _setupRole(MINTER_ROLE, 0x93BD8b204D06C4510400048781cc279Baf8480e7);
        _setupRole(PRICE_UPDATER_ROLE, 0xC9953804913e7092668487B49a2acd259217D2eD);

        for (uint256 index = 0; index < _category.length; index++) {
            landCategory[_category[index]].priceInUSD = _categoryDetail[index][
                0
            ].mul(1 ether);
            landCategory[_category[index]].status = true;
            landCategory[_category[index]].maxCategorySupply = _categoryDetail[
                index
            ][1];
            landCategory[_category[index]].slotIndependent = _slotDependency[
                index
            ];
            landCategory[_category[index]].startRange = _categoryDetail[index][
                2
            ];
            landCategory[_category[index]].endRange = _categoryDetail[index][3];
        }

        for (uint256 index = 0; index < _slot.length; index++) {
            slot[_slot[index][0]].startTime = _slot[index][1];
            slot[_slot[index][0]].endTime = _slot[index][2];

            slotCount++;

            slot[_slot[index][0]]
                .slotSupply[_category[0]]
                .maxSlotCategorySupply = _slotSupply[index][0];
            slot[_slot[index][0]]
                .slotSupply[_category[1]]
                .maxSlotCategorySupply = _slotSupply[index][1];
            slot[_slot[index][0]]
                .slotSupply[_category[2]]
                .maxSlotCategorySupply = _slotSupply[index][2];
            slot[_slot[index][0]]
                .slotSupply[_category[3]]
                .maxSlotCategorySupply = _slotSupply[index][3];
            slot[_slot[index][0]]
                .slotSupply[_category[4]]
                .maxSlotCategorySupply = _slotSupply[index][4];
        }
    }

    function buyLandWithTVK(
        uint256 _slot,
        string memory _category,
        uint256 _tokenId,
        bytes32 _hash,
        bytes memory _signature
    ) public {
        uint256 _price = getlandPriceInTVK(_category);
        require(tvkPaymentEnabled, "Landsale: TVK payment disabled!");
        require(
            block.timestamp >= slot[1].startTime,
            "LandSale: Sale not started yet!"
        );
        require(landCategory[_category].status, "Landsale: Invalid caetgory!");
        require(
            _tokenId >= landCategory[_category].startRange &&
                _tokenId <= landCategory[_category].endRange,
            "Landsale: Invalid token id for category range!"
        );
        require(
            recover(_hash, _signature) == signatureAddress,
            "Landsale: Invalid signature!"
        );
        require(!signatures[_signature], "Landsale: Signature already used!");
        require(
            TVK.allowance(msg.sender, address(this)) >= _price,
            "Landsale: Allowance to spend token not enough!"
        );

        TVK.transferFrom(msg.sender, address(this), _price);

        slotValidation(_slot, _category, _tokenId, msg.sender);

        signatures[_signature] = true;

        emit landBoughtWithTVK(
            _tokenId,
            _price,
            msg.sender,
            _category,
            _slot,
            _signature
        );
    }

    function buyLandWithETH(
        uint256 _slot,
        string memory _category,
        uint256 _tokenId,
        bytes32 _hash,
        bytes memory _signature
    ) public payable {
        require(ethPaymentEnabled, "Landsale: Eth payment disabled!");
        require(
            block.timestamp >= slot[1].startTime,
            "LandSale: Sale not started yet!"
        );
        require(
            msg.value == getlandPriceInETH(_category),
            "Landsale: Invalid payment!"
        );
        require(landCategory[_category].status, "Landsale: Invalid caetgory!");
        require(
            _tokenId >= landCategory[_category].startRange &&
                _tokenId <= landCategory[_category].endRange,
            "Landsale! Invalid token id for category range!"
        );
        require(
            recover(_hash, _signature) == signatureAddress,
            "Landsale: Invalid signature!"
        );
        require(!signatures[_signature], "Landsale: Signature already used!");

        slotValidation(_slot, _category, _tokenId, msg.sender);

        signatures[_signature] = true;

        emit landBoughtWithETH(
            _tokenId,
            msg.value,
            msg.sender,
            _category,
            _slot,
            _signature
        );
    }

    function adminMint(
        uint256[] memory _tokenId,
        string memory _category,
        address[] memory _beneficiary
    ) public {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Landsale: Must have price update role to mint."
        );
        require(landCategory[_category].status, "Landsale: Invalid caetgory!");
        require(
            landCategory[_category].mintedCategorySupply.add(_tokenId.length) <=
                landCategory[_category].maxCategorySupply,
            "LandSale: Max category supply reached!"
        );
        require(
            totalSupply.add(_tokenId.length) <= cappedSupply,
            "Landsale: Max total supply reached!"
        );
        require(
            _tokenId.length == _beneficiary.length,
            "Landsale: Token ids and beneficiary addresses are not equal."
        );

        for (uint256 index = 0; index < _tokenId.length; index++) {
            NFT.mint(_beneficiary[index], _tokenId[index]);
        }

        landCategory[_category].mintedCategorySupply = landCategory[_category]
            .mintedCategorySupply
            .add(_tokenId.length);
        totalSupply = totalSupply.add(_tokenId.length);

        emit adminMintedItem(_category, _tokenId, _beneficiary);
    }

    function slotValidation(
        uint256 _slot,
        string memory _category,
        uint256 _tokenId,
        address _beneficiary
    ) internal {
        if (landCategory[_category].slotIndependent) {
            mintToken(_slot, _category, _tokenId, _beneficiary);
        } else if (
            block.timestamp >= slot[_slot].startTime &&
            block.timestamp <= slot[_slot].endTime
        ) {
            require(
                slot[_slot].slotSupply[_category].maxSlotCategorySupply > 0,
                "Landsale: This land category cannot be bought in this slot!"
            );

            mintToken(_slot, _category, _tokenId, _beneficiary);
        } else if (block.timestamp > slot[_slot].endTime) {
            revert("Landsale: Slot ended!");
        } else if (block.timestamp < slot[_slot].startTime) {
            revert("Landsale: Slot not started yet!");
        }
    }

    function mintToken(
        uint256 _slot,
        string memory _category,
        uint256 _tokenId,
        address _beneficiary
    ) internal {
        require(
            landCategory[_category].mintedCategorySupply.add(1) <=
                landCategory[_category].maxCategorySupply,
            "LandSale: Max category supply reached!"
        );
        require(
            slot[_slot].slotSupply[_category].mintedSlotCategorySupply.add(1) <=
                slot[_slot].slotSupply[_category].maxSlotCategorySupply,
            "Landsale: Max slot category supply reached!"
        );
        require(
            totalSupply.add(1) <= cappedSupply,
            "Landsale: Max total supply reached!"
        );

        slot[_slot].slotSupply[_category].mintedSlotCategorySupply++;
        landCategory[_category].mintedCategorySupply++;
        totalSupply++;

        NFT.mint(_beneficiary, _tokenId);
    }

    function setEthPaymentToggle() public {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "Landsale: Must have admin role to set eth toggle."
        );
        if (ethPaymentEnabled) {
            ethPaymentEnabled = false;
        } else {
            ethPaymentEnabled = true;
        }
    }

    function setTvkPaymentToggle() public {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "Landsale: Must have admin role to set tvk toggle."
        );
        if (tvkPaymentEnabled) {
            tvkPaymentEnabled = false;
        } else {
            tvkPaymentEnabled = true;
        }
    }

    function addNewLandCategory(
        string memory _category,
        bool _slotIndependency,
        uint256 _priceInUSD,
        uint256 _maxCategorySupply,
        uint256 _categoryStartRange,
        uint256 _categoryEndRange
    ) public {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "Landsale: Must have admin role to add new land category."
        );
        require(
            landCategory[_category].status == false,
            "LandSale: Category already exist!"
        );
        require(_priceInUSD > 0, "LandSale: Invalid price in TVK!");
        require(_maxCategorySupply > 0, "LandSale: Invalid max Supply!");
        require(_categoryStartRange <= _categoryEndRange , "LandSale: Start range must be smaller than or equal to end range!");
        require(_categoryStartRange > 0, "LandSale: Start range must be greater than 0!");
        require(_categoryEndRange > 0, "LandSale: End range must be greater than 0!");        

        landCategory[_category].priceInUSD = _priceInUSD.mul(1 ether);
        landCategory[_category].status = true;
        landCategory[_category].maxCategorySupply = _maxCategorySupply;
        landCategory[_category].slotIndependent = _slotIndependency;
        landCategory[_category].startRange = _categoryStartRange;
        landCategory[_category].endRange = _categoryEndRange;

        cappedSupply = cappedSupply.add(_maxCategorySupply);

        for (uint256 index = 1; index <= slotCount; index++) {
            slot[index]
                .slotSupply[_category]
                .maxSlotCategorySupply = _maxCategorySupply;
        }

        emit newLandCategoryAdded(_category, _priceInUSD, _maxCategorySupply);
    }

    function addNewSlot(
        uint256 _slot,
        uint256 _startTime,
        uint256 _endTime,
        string[] memory _category,
        uint256[] memory _slotSupply
    ) public {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "Landsale: Must have admin role to add new slot."
        );
        require(_slot == slotCount.add(1), "Landsale: New slot should increment of last slot.");
        require(_startTime >= block.timestamp, "Landsale: Invalid start time!");
        require(_endTime > _startTime, "Landsale: Invalid end time!");
        require(
            _category.length == _slotSupply.length,
            "Landsale: Invalid length of category and status!"
        );

        slot[_slot].startTime = _startTime;
        slot[_slot].endTime = _endTime;

        for (uint256 index = 0; index < _category.length; index++) {
            slot[_slot]
                .slotSupply[_category[index]]
                .maxSlotCategorySupply = _slotSupply[index];
        }
        slotCount++;

        emit newSlotAdded(_slot, _startTime, _endTime, _category, _slotSupply);
    }

    function updateTVKperUSDprice(uint256 _TVKperUSDprice) public {
        require(
            hasRole(PRICE_UPDATER_ROLE, _msgSender()),
            "Landsale: Must have price updater role to update tvk price"
        );
        require(_TVKperUSDprice > 0, "Landsale: Invalid price!");
        require(_TVKperUSDprice != TVKperUSDprice , "Landsale: TVK price already same.");

        TVKperUSDprice = _TVKperUSDprice;

        emit TVKperUSDpriceUpdated(_TVKperUSDprice);
    }

    function updateETHperUSDprice(uint256 _ETHperUSDprice) public {
        require(
            hasRole(PRICE_UPDATER_ROLE, _msgSender()),
            "Landsale: Must have price updater role to update eth price"
        );
        require(_ETHperUSDprice > 0, "Landsale: Invalid price!");
        require(_ETHperUSDprice != ETHperUSDprice, "Landsale: ETH price already same");

        ETHperUSDprice = _ETHperUSDprice;

        emit ETHperUSDpriceUpdated(_ETHperUSDprice);
    }

    function updateLandCategoryPriceInUSD(
        string memory _category,
        uint256 _price
    ) public {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "Landsale: Must have admin role to update category price."
        );
        require(
            landCategory[_category].status == true,
            "LandSale: Non-Existing category!"
        );
        require(_price > 0, "LandSale: Invalid price!");

        landCategory[_category].priceInUSD = _price.mul(1 ether); 

        emit landCategoryPriceUpdated(_category, _price);
    }

    function updateCategorySupplyInSlot(
        string memory _category,
        uint256 _slot,
        uint256 _slotSupply
    ) public {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "Landsale: Must have admin role to update category supply in slot."
        );
        require(landCategory[_category].status, "Landsale: Invalid category!");
        require(
            landCategory[_category].maxCategorySupply >= _slotSupply,
            "LandSale: Slot supply cannot be greater than max category supply!"
        );

        slot[_slot].slotSupply[_category].maxSlotCategorySupply = _slotSupply;

        emit categoryAvailabilityInSlotUpdated(_category, _slot, _slotSupply);
    }

    function updateSlotStartTime(uint256 _slot, uint256 _startTime) public {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "Landsale: Must have admin role to update slot time"
        );
        require(_slot > 0 && _slot <= slotCount, "Landsale: Invalid slot!");
        require(_startTime > block.timestamp, "Landsale: Invalid start time!");

        slot[_slot].startTime = _startTime;

        emit slotStartTimeUpdated(_slot, _startTime);
    }

    function updateSlotEndTime(uint256 _slot, uint256 _endTime) public {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "Landsale: Must have admin role to update slot time"
        );
        require(_slot > 0 && _slot <= slotCount, "Landsale: Invalid slot!");
        require(_endTime > slot[_slot].startTime, "Landsale: Invalid start time!");

        slot[_slot].endTime = _endTime;

        emit slotEndTimeUpdated(_slot, _endTime);
    }

    function updateSignatureAddress(address _signatureAddress)
        public
        onlyOwner
    {
        require(_signatureAddress != address(0), "Landsale: Invalid address!");
        require(_signatureAddress != signatureAddress, "Landsale: Address already exist.");

        signatureAddress = _signatureAddress;

        emit signatureAddressUpdated(_signatureAddress);
    }

    function updateTVKAddress(address _address) public onlyOwner {
        require(_address != address(0), "Landsale: Invalid address!");
        require(IERC20(_address) != TVK, "Landsale: Address already exist.");
        TVK = IERC20(_address);

        emit TVKAddressUpdated(_address);
    }

    function updateNFTAddress(address _address) public onlyOwner {
        require(_address != address(0), "Landsale: Invalid address!");
        require(IERC721(_address) != NFT, "Landsale: Address already exist.");

        NFT = IERC721(_address);

        emit NFTAddressUpdated(_address);
    }

    function updateWithdrawAddress(address payable _withdrawAddress)
        public
        onlyOwner
    {
        require(_withdrawAddress != address(0), "Landsale: Invalid address!");
        require(_withdrawAddress != withdrawAddress, "Landsale: Address already exist.");
        withdrawAddress = _withdrawAddress;

        emit withdrawAddressUpdated(_withdrawAddress);
    }

    function withdrawEthFunds() public onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        require(amount > 0, "Dapp: invalid amount.");
        withdrawAddress.transfer(amount);

        emit ETHFundsWithdrawn(amount);
    }

    function withdrawTokenFunds() public onlyOwner nonReentrant {
        uint256 amount = TVK.balanceOf(address(this));
        require(amount > 0, "Landsale: invalid amount!");
        TVK.transfer(withdrawAddress, amount);

        emit TVKFundsWithdrawn(amount);
    }

    function updateCategoryToSlotIndependent(
        string memory _category,
        bool _slotDependency
    ) public  {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "Landsale: Must have admin role to add new land category."
        );
        require(landCategory[_category].status, "Landsale: Invlaid category!");

        landCategory[_category].slotIndependent = _slotDependency;
    }

    function getTokenBalance() public view returns (uint256) {
        return TVK.balanceOf(address(this));
    }

    function getWithdrawAddress() public view returns (address) {
        return withdrawAddress;
    }

    function getSignatureAddress()
        public
        view
        returns (address _signatureAddress)
    {
        _signatureAddress = signatureAddress;
    }

    function getTVKAddress() public view returns (IERC20 _TVK) {
        _TVK = TVK;
    }

    function getNFTAddress() public view returns (IERC721 _NFT) {
        _NFT = NFT;
    }

    function getSlotStartTimeAndEndTime(uint256 _slot)
        public
        view
        returns (uint256 _startTime, uint256 _endTime)
    {
        _startTime = slot[_slot].startTime;
        _endTime = slot[_slot].endTime;
    }

    function getCategorySupplyBySlot(string memory _category, uint256 _slot)
        public
        view
        returns (uint256 _slotSupply)
    {
        _slotSupply = slot[_slot].slotSupply[_category].maxSlotCategorySupply;
    }

    function getCategoryDetails(string memory _category)
        public
        view
        returns (
            uint256 _priceInUSD,
            uint256 _maxSlotCategorySupply,
            uint256 _mintedCategorySupply,
            bool _status,
            bool _slotIndependent
        )
    {
        _priceInUSD = landCategory[_category].priceInUSD;
        _mintedCategorySupply = landCategory[_category].mintedCategorySupply;
        _maxSlotCategorySupply = landCategory[_category].maxCategorySupply;
        _status = landCategory[_category].status;
        _slotIndependent = landCategory[_category].slotIndependent;
    }

    function getCategoryRanges(string memory _category)
        public
        view
        returns (uint256 _startRange, uint256 _endRange)
    {
        _startRange = landCategory[_category].startRange;
        _endRange = landCategory[_category].endRange;
    }

    function getlandPriceInTVK(string memory _category)
        public
        view
        returns (uint256 _price)
    {
        _price = (landCategory[_category].priceInUSD.mul(TVKperUSDprice)).div(
            1 ether
        );
    }

    function getlandPriceInETH(string memory _category)
        public
        view
        returns (uint256 _price)
    {
        _price = (landCategory[_category].priceInUSD.mul(ETHperUSDprice)).div(
            1 ether
        );
    }

    function checkSignatureValidity(bytes memory _signature)
        public
        view
        returns (bool)
    {
        return signatures[_signature];
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function getCappedSupply() public view returns (uint256) {
        return cappedSupply;
    }

    function getSlotCount() public view returns (uint256) {
        return slotCount;
    }

    function getTVKperUSDprice() public view returns (uint256) {
        return TVKperUSDprice;
    }

    function getETHperUSDprice() public view returns (uint256) {
        return ETHperUSDprice;
    }

    function getETHPaymentEnabled() public view returns (bool) {
        return ethPaymentEnabled;
    }

    function getTVKPaymentEnabled() public view returns (bool) {
        return tvkPaymentEnabled;
    }

    function recover(bytes32 _hash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (_signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(_hash, v, r, s);
        }
    }
}