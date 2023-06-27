//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Escrow {
    using SafeERC20 for IERC20;

    /*==============================================================
                            CONSTANTS
    ==============================================================*/

    /// @notice The owner of the contract
    address public immutable owner;

    /*==============================================================
                            VARIABLES
    ==============================================================*/

    enum DepositType {
        ETH,
        ERC20,
        ERC721
    }

    /// @notice The deposit struct
    struct Deposit {
        /// @notice The buyer address
        address buyer;
        /// @notice The seller address
        address seller;
        /// @notice The amount of the deposit (applies when deposit type is ETH or ERC20)
        uint256 amount;
        /// @notice The token address (if the deposit is ERC20 or ERC721)
        address token;
        /// @notice The token IDs (if the deposit is ERC721)
        uint256[] tokenIds;
        /// @notice The deposit type (ETH, ERC20, ERC721)
        DepositType depositType;
        /// @notice Whether the deposit has been released
        bool released;
    }

    /// @notice The current deposit ID
    uint256 public currentId;

    /// @notice The accrued fees
    uint256 public accruedFeesETH;

    mapping(address => uint256) public accruedFeesERC20;

    /// @notice The deposits mapping
    mapping(uint256 => Deposit) public deposits;

    /*==============================================================
                            MODIFIERS
    ==============================================================*/

    /// @notice Only owner can execute
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }
        _;
    }

    /// @notice Only non-released deposits can be released
    /// @param _id The deposit ID
    modifier releaseGuard(uint256 _id) {
        Deposit storage deposit = deposits[_id];
        if (deposit.buyer == address(0)) {
            revert DepositDoesNotExist();
        }

        if (deposit.released == true) {
            revert AlreadyReleased();
        }
        _;
    }

    modifier nonEmptySeller(address _seller) {
        if (_seller == address(0)) {
            revert SellerAddressEmpty();
        }
        _;
    }

    /*==============================================================
                            FUNCTIONS
    ==============================================================*/

    constructor() {
        owner = msg.sender;
    }

    /// @notice Creates a new ETH deposit
    /// @param _seller The seller address
    function createDepositETH(
        address _seller
    ) external payable nonEmptySeller(_seller) {
        if (msg.value == 0) {
            revert DepositAmountZero();
        }

        Deposit memory deposit;
        deposit.buyer = msg.sender;
        deposit.seller = _seller;
        deposit.amount = msg.value;
        deposit.depositType = DepositType.ETH;
        deposits[++currentId] = deposit;

        emit NewDepositETH(currentId, msg.sender, _seller, msg.value);
    }

    /// @notice Creates a new ERC20 deposit
    /// @param _seller The seller address
    /// @param _token The token address
    /// @param _amount The amount of tokens
    function createDepositERC20(
        address _seller,
        address _token,
        uint256 _amount
    ) external nonEmptySeller(_seller) {
        if (_token == address(0)) {
            revert TokenAddressEmpty();
        }

        if (_amount == 0) {
            revert DepositAmountZero();
        }

        Deposit memory deposit;
        deposit.buyer = msg.sender;
        deposit.seller = _seller;
        deposit.amount = _amount;
        deposit.token = _token;
        deposit.depositType = DepositType.ERC20;
        deposits[++currentId] = deposit;

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        emit NewDepositERC20(currentId, msg.sender, _seller, _token, _amount);
    }

    /// @notice Creates a new ERC721 deposit
    /// @param _seller The seller address
    /// @param _token The token address
    /// @param _tokenIds The token IDs
    function createDepositERC721(
        address _seller,
        address _token,
        uint256[] calldata _tokenIds
    ) external nonEmptySeller(_seller) {
        if (_token == address(0)) {
            revert TokenAddressEmpty();
        }

        if (_tokenIds.length == 0) {
            revert NoTokenIds();
        }

        Deposit memory deposit;
        deposit.buyer = msg.sender;
        deposit.seller = _seller;
        deposit.token = _token;
        deposit.tokenIds = _tokenIds;
        deposit.depositType = DepositType.ERC721;
        deposits[++currentId] = deposit;

        uint256 length = _tokenIds.length;
        for (uint256 i = 0; i < length; ++i) {
            IERC721(_token).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );
        }

        emit NewDepositERC721(
            currentId,
            msg.sender,
            _seller,
            _token,
            _tokenIds
        );
    }

    function releaseDeposit(uint256 _id) external releaseGuard(_id) {
        Deposit storage deposit = deposits[_id];
        if (deposit.buyer != msg.sender) {
            revert OnlyBuyer();
        }

        deposit.released = true;

        if (deposit.depositType == DepositType.ETH) {
            _releaseDepositETH(deposit.seller, deposit.amount);
        } else if (deposit.depositType == DepositType.ERC20) {
            _releaseDepositERC20(deposit.seller, deposit.token, deposit.amount);
        } else if (deposit.depositType == DepositType.ERC721) {
            _releaseDepositERC721(
                deposit.seller,
                deposit.token,
                deposit.tokenIds
            );
        }

        emit DepositReleased(_id);
    }

    /// @notice Allows the owner to release a deposit
    /// @param _id The current deposit id
    /// @param _to The address to send the funds to
    function intervene(
        uint256 _id,
        address _to
    ) external releaseGuard(_id) onlyOwner {
        Deposit storage deposit = deposits[_id];
        deposit.released = true;

        if (deposit.depositType == DepositType.ETH) {
            _releaseDepositETH(_to, deposit.amount);
        } else if (deposit.depositType == DepositType.ERC20) {
            _releaseDepositERC20(_to, deposit.token, deposit.amount);
        } else if (deposit.depositType == DepositType.ERC721) {
            _releaseDepositERC721(_to, deposit.token, deposit.tokenIds);
        }

        emit Intervened(_id, _to);
    }

    /// @notice Allows the buyer to release the ETH deposit
    /// @param _seller The seller address
    /// @param _amount The amount of ETH
    function _releaseDepositETH(address _seller, uint256 _amount) internal {
        uint256 fee = _calculateFee(_amount);
        uint256 releaseAmount = _amount - fee;

        accruedFeesETH += fee;

        (bool success, ) = payable(_seller).call{value: releaseAmount}("");
        if (!success) {
            revert FailedToSendReleasedETH();
        }
    }

    /// @notice Allows the buyer to release the ERC20 deposit
    /// @param _seller The seller address
    /// @param _token The token address
    /// @param _amount The amount of tokens
    function _releaseDepositERC20(
        address _seller,
        address _token,
        uint256 _amount
    ) internal {
        uint256 fee = _amount / 200;
        uint256 releaseAmount = _amount - fee;

        accruedFeesERC20[_token] += fee;

        IERC20(_token).safeTransfer(_seller, releaseAmount);
    }

    /// @notice Allows the buyer to release the ERC721 deposit
    /// @param _seller The seller address
    /// @param _token The token address
    /// @param _tokenIds The token IDs
    function _releaseDepositERC721(
        address _seller,
        address _token,
        uint256[] memory _tokenIds
    ) internal {
        uint256 length = _tokenIds.length;
        for (uint256 i = 0; i < length; ++i) {
            IERC721(_token).safeTransferFrom(
                address(this),
                _seller,
                _tokenIds[i]
            );
        }
    }

    /// @notice Allows the owner to withdraw the accrued ETH fees
    /// @param _to The address to send the fees to
    function withdrawFeesETH(address _to) external onlyOwner {
        if (accruedFeesETH == 0) {
            revert NoFeesAccrued();
        }

        uint256 feesToTransfer = accruedFeesETH;
        accruedFeesETH = 0;

        (bool success, ) = payable(_to).call{value: feesToTransfer}("");
        if (!success) {
            revert FailedToSendWithdrawnETH();
        }
    }

    /// @notice Allows the owner to withdraw the accrued ERC20 fees
    /// @param _to The address to send the fees to
    /// @param _token The token address
    function withdrawFeesERC20(address _to, address _token) external onlyOwner {
        if (accruedFeesERC20[_token] == 0) {
            revert NoFeesAccrued();
        }

        uint256 feesToTransfer = accruedFeesERC20[_token];
        accruedFeesERC20[_token] = 0;

        IERC20(_token).safeTransfer(_to, feesToTransfer);
    }

    /// @notice Calculates the fee for a deposit
    /// @param _amount The amount to deposit
    /// @return Fees for the deposit
    function _calculateFee(uint256 _amount) internal pure returns (uint256) {
        return _amount / 200;
    }

    /// @notice Allows the contract to receive ERC721 tokens
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /*==============================================================
                            EVENTS
    ==============================================================*/

    /// @notice Emitted when a new deposit is created
    /// @param currentId The current deposit id
    /// @param buyer The buyer address
    /// @param seller The seller address
    /// @param amount The amount of the deposit
    event NewDepositETH(
        uint256 indexed currentId,
        address indexed buyer,
        address indexed seller,
        uint256 amount
    );

    /// @notice Emitted when a new deposit is created
    /// @param currentId The current deposit id
    /// @param buyer The buyer address
    /// @param seller The seller address
    /// @param token The token address
    /// @param amount The amount of the deposit
    event NewDepositERC20(
        uint256 indexed currentId,
        address indexed buyer,
        address indexed seller,
        address token,
        uint256 amount
    );

    /// @notice Emitted when a new deposit is created
    /// @param currentId The current deposit id
    /// @param buyer The buyer address
    /// @param seller The seller address
    /// @param token The token address
    /// @param tokenIds The token ids
    event NewDepositERC721(
        uint256 indexed currentId,
        address indexed buyer,
        address indexed seller,
        address token,
        uint256[] tokenIds
    );

    /// @notice Emitted when a deposit is released
    /// @param id Deposit id
    event DepositReleased(uint256 indexed id);

    /// @notice Emitted when the owner withdraws fees
    /// @param id The deposit id
    /// @param to The address to which the deposit is sent
    event Intervened(uint256 indexed id, address indexed to);

    /*==============================================================
                            ERRORS
    ==============================================================*/

    error OnlyOwner();

    error OnlyBuyer();

    error DepositDoesNotExist();

    error AlreadyReleased();

    error FailedToSendReleasedETH();

    error FailedToSendWithdrawnETH();

    error NoFeesAccrued();

    error NoTokenIds();

    error DepositAmountZero();

    error TokenAddressEmpty();

    error SellerAddressEmpty();

    error FailedToTransferERC20();

    error FailedToTransferERC721();

    error FailedToSendReleasedERC20();

    error FailedToSendReleasedERC721();
}