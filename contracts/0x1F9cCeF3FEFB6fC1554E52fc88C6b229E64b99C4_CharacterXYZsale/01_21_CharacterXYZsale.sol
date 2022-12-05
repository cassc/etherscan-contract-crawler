// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./CharacterXYZ.sol";

contract CharacterXYZsale is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    event Mint(uint256 indexed id, address to, uint256 amount);

    struct collectionStruct {
        uint256 totalSupply;
        uint256 totalMinted;
        uint256 fee;
    }

    struct lendStruct {
        uint256 amount;
        uint256 feePerCopy;
        uint256 timePeriod;
    }

    mapping(uint256 => collectionStruct) public collections;
    mapping(address => mapping(uint256 => lendStruct)) public lendMap;

    // holder , owner , collection id, expiryTime
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        public rentalMap;

    CharacterXYZ public tokenContract;
    address public fundsReciever;
    uint256 public lendingFee;

    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    function initialize(
        CharacterXYZ _tokenContract,
        address _fundsReciever,
        uint256 _lendingFee
    ) public initializer {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MODERATOR_ROLE, msg.sender);

        tokenContract = _tokenContract;
        fundsReciever = _fundsReciever;
        lendingFee = _lendingFee;
    }

    //----- External Functions -----//

    receive() external payable {
        revert();
    }

    //----- Administrative Functions -----//

    function setupCollection(
        uint256 _collectionId,
        uint256 _totalSaleSupply,
        uint256 _feePerToken
    ) external onlyRole(MODERATOR_ROLE) {
        if (collections[_collectionId].totalMinted == 0)
            collections[_collectionId] = collectionStruct(
                _totalSaleSupply,
                0,
                _feePerToken
            );
        else {
            require(
                collections[_collectionId].totalMinted <= _totalSaleSupply,
                "_totalSaleSupply cannot be less than already Minted Tokens"
            );
            collections[_collectionId].totalSupply = _totalSaleSupply;
            collections[_collectionId].fee = _feePerToken;
        }
    }

    function withdrawFunds(address _reciever)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        AddressUpgradeable.sendValue(payable(_reciever), address(this).balance);
    }

    function setFundsReceiver(address _reciever)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        fundsReciever = _reciever;
    }

    /**
     * @dev To set fee for withdrawal of tokens.
     * @param _lendingFee, fee to set in wei amounts. For example fee = 100000000000000000 means 0.1 % of amount
     */
    function setLendingFee(uint256 _lendingFee)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lendingFee = _lendingFee;
    }

    //----- Public Functions -----//

    function lendNFT(
        uint256 _collectionId,
        uint256 _amount,
        uint256 _feePerCopy,
        uint256 _timePeriod
    ) public {
        require(_amount > 0, "_amount cannot be 0");
        require(_feePerCopy > 0, "_feePerCopy cannot be 0");
        require(_timePeriod > 0, "_timePeriod cannot be 0");

        require(
            tokenContract.isApprovedForAll(msg.sender, address(this)) == true,
            "Approval not given to this contract"
        );
        require(
            tokenContract.balanceOf(msg.sender, _collectionId) >= _amount,
            "Amount should be within your collection copies count"
        );

        require(
            lendMap[msg.sender][_collectionId].amount == 0,
            "Lending already set against this collection"
        );

        lendMap[msg.sender][_collectionId] = lendStruct(
            _amount,
            _feePerCopy,
            _timePeriod
        );
    }

    function calculateFeeAfterPlatformCharges(uint256 _value)
        public
        view
        returns (uint256)
    {
        return _value - ((lendingFee * _value) / (10**18) / 100);
    }

    function rentNFT(address _owner, uint256 _collectionId) public payable {
        require(
            tokenContract.isApprovedForAll(msg.sender, address(this)) == true,
            "Approval not given to this contract"
        );

        require(
            tokenContract.balanceOf(msg.sender, _collectionId) == 0,
            "You already own collection with this id"
        );

        require(
            msg.value == lendMap[_owner][_collectionId].feePerCopy,
            "Value not equal to cost"
        );
        require(
            lendMap[_owner][_collectionId].amount > 0,
            "Available copies for rent are zero"
        );

        lendMap[_owner][_collectionId].amount -= 1;

        AddressUpgradeable.sendValue(
            payable(_owner),
            calculateFeeAfterPlatformCharges(msg.value)
        );

        AddressUpgradeable.sendValue(
            payable(fundsReciever),
            msg.value - calculateFeeAfterPlatformCharges(msg.value)
        );

        tokenContract.setBlockTransfer(msg.sender, _collectionId, true);

        tokenContract.safeTransferFrom(
            _owner,
            msg.sender,
            _collectionId,
            1,
            bytes("")
        );

        rentalMap[msg.sender][_owner][_collectionId] =
            block.timestamp +
            lendMap[_owner][_collectionId].timePeriod;
    }

    function getNFTback(uint256 _collectionId, address _holder) public {
        require(
            rentalMap[_holder][msg.sender][_collectionId] < block.timestamp,
            "Expiry time not reached yet"
        );

        delete rentalMap[_holder][msg.sender][_collectionId];

        tokenContract.setBlockTransfer(_holder, _collectionId, false);

        tokenContract.safeTransferFrom(
            _holder,
            msg.sender,
            _collectionId,
            1,
            bytes("")
        );
    }

    function mintNFT(
        uint256 _collectionId,
        address _to,
        uint256 amount
    ) public payable whenNotPaused {
        require(
            tokenContract.isTransferBlocked(_to, _collectionId) == false,
            "Return Rented NFT of this collection first, to mint this collection"
        );
        require(amount > 0, "Amount should be greater than 0");

        require(
            msg.value == collections[_collectionId].fee * amount,
            "Value not equal to Fee"
        );
        require(
            collections[_collectionId].totalMinted + amount <=
                collections[_collectionId].totalSupply,
            "Not within Mintable Supply"
        );

        collections[_collectionId].totalMinted += amount;

        AddressUpgradeable.sendValue(payable(fundsReciever), msg.value);

        tokenContract.mint(_to, _collectionId, amount, bytes(""));

        emit Mint(_collectionId, _to, amount);
    }

    //----- The following Functions are overrides required by Solidity -----//

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}