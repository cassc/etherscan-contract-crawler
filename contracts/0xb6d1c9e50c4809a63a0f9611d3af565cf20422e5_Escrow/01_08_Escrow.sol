// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IEscrow.sol";

contract Escrow is IEscrow, Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    bool private initialized;
    address public client;
    address public talent;
    address public resolver;

    uint256 public released;

    uint256 public fee = 1500;

    struct Confirmation {
        address from;
        address token;
        uint256 amount;
    }

    uint8 private constant RELEASE = 1;
    uint8 private constant REFUND = 2;

    mapping(uint8 => mapping(bytes => uint8)) public votes;
    mapping(uint8 => mapping(bytes => mapping(address => bool)))
        public isConfirmed;

    event Confirmed(address from, address token, uint256 amount, uint8 vote);
    event Released(
        address from,
        address to,
        address token,
        uint256 amount,
        string note
    );
    event Refunded(
        address from,
        address to,
        address token,
        uint256 amount,
        string note
    );
    event Deposit(
        address from,
        address to,
        address token,
        uint256 amount,
        string note
    );

    function init(
        address _client,
        address _provider,
        address _resolver,
        uint256 _fee
    ) external payable override initializer {
        require(_client != address(0), "Client address required");
        require(_provider != address(0), "Provider address required");
        require(_resolver != address(0), "Resolver address required");
        require(_fee < 10000, "Fee must be a value of 0 - 99999");
        client = _client;
        talent = _provider;
        resolver = _resolver;

        fee = _fee;

        initialized = true;
    }

    modifier onlyParty() {
        require(
            msg.sender == client ||
                msg.sender == talent ||
                msg.sender == resolver,
            "Sender not part of party"
        );
        _;
    }

    modifier onlyInitialized() {
        require(initialized, "Escrow must be initialized");
        _;
    }

    /// @notice Receive eth deposits
    receive() external payable {
        emit Deposit(msg.sender, talent, address(0), msg.value, "direct");
    }

    /// @notice Deposit ETH
    /// @param _releaseAmount Amount to release

    function deposit(uint256 _releaseAmount, string memory _note)
        external
        payable
        onlyInitialized
        nonReentrant
    {
        emit Deposit(msg.sender, talent, address(0), msg.value, _note);
        if (_releaseAmount > 0) {
            _release(_releaseAmount, _note);
        }
    }

    /// @notice Deposit ERC20 tokens
    /// @param _token ERC20 address to token to be transferred
    /// @param _amount Amount of tokens to transfer
    /// @param _releaseAmount Amount to release

    function deposit(
        address _token,
        uint256 _amount,
        uint256 _releaseAmount,
        string memory _note
    ) external onlyInitialized nonReentrant {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, talent, _token, _amount, _note);

        if (_releaseAmount > 0) {
            _release(_token, _releaseAmount, _note);
        }
    }

    /// @notice Counts votes for release or refunds. Each set of token and amount is unique.
    /// @param _type Either REFUND or RELEASE
    /// @param _token ERC20 address to token to be transferred
    /// @param _amount Amount of tokens to transfer
    /// @return True if vote count is a majority (2)
    function countVotes(
        uint8 _type,
        address _token,
        uint256 _amount
    ) internal returns (bool) {
        bytes memory hash = abi.encodePacked(_token, _amount);
        require(!isConfirmed[_type][hash][msg.sender], "Already confirmed");
        isConfirmed[_type][hash][msg.sender] = true;

        votes[_type][hash] += 1;

        emit Confirmed(msg.sender, _token, _amount, _type);

        return votes[_type][hash] == 2;
    }

    /// @notice Resets the votes for release or refunds. Called after successful transfer of tokens.
    /// @param _type Either REFUND or RELEASE
    /// @param _token ERC20 address to token to be transferred
    /// @param _amount Amount of tokens to transfer
    function resetVotes(
        uint8 _type,
        address _token,
        uint256 _amount
    ) internal {
        bytes memory hash = abi.encodePacked(_token, _amount);
        votes[_type][hash] = 0;
        isConfirmed[_type][hash][client] = false;
        isConfirmed[_type][hash][talent] = false;
        isConfirmed[_type][hash][resolver] = false;
    }

    /// @notice Refunds eth to client
    function refund(uint256 _amount, string memory _note)
        external
        override
        onlyParty
        onlyInitialized
        nonReentrant
    {
        if (countVotes(REFUND, address(0), _amount)) {
            Address.sendValue(payable(client), _amount);

            resetVotes(REFUND, address(0), _amount);
            emit Refunded(msg.sender, client, address(0), _amount, _note);
        }
    }

    /// @notice Refunds tokens to client
    function refund(
        address _token,
        uint256 _amount,
        string memory _note
    ) external override onlyParty onlyInitialized nonReentrant {
        if (countVotes(REFUND, _token, _amount)) {
            IERC20(_token).safeTransfer(client, _amount);

            resetVotes(REFUND, _token, _amount);
            emit Refunded(msg.sender, client, _token, _amount, _note);
        }
    }

    /// @notice Releases eth to talent and resolver
    function release(uint256 _amount, string memory _note)
        public
        payable
        override
        onlyParty
        onlyInitialized
        nonReentrant
    {
        bool isClient = msg.sender == client;
        if (isClient || countVotes(RELEASE, address(0), _amount)) {
            _release(_amount, _note);
        }
    }

    /// @notice Releases tokens to talent and resolver
    function release(
        address _token,
        uint256 _amount,
        string memory _note
    ) public override onlyParty onlyInitialized nonReentrant {
        bool isClient = msg.sender == client;
        if (isClient || countVotes(RELEASE, _token, _amount)) {
            _release(_token, _amount, _note);
        }
    }

    function _release(uint256 _amount, string memory _note) internal {
        released += _amount;
        emit Released(msg.sender, talent, address(0), _amount, _note);
        uint256 resolverShare = calcShare(_amount);
        Address.sendValue(payable(resolver), resolverShare); // resolver payout
        Address.sendValue(payable(talent), _amount - resolverShare); // talent payout
    }

    function _release(
        address _token,
        uint256 _amount,
        string memory _note
    ) internal {
        uint256 resolverShare = calcShare(_amount);
        IERC20(_token).safeTransfer(resolver, resolverShare); // resolver payout
        IERC20(_token).safeTransfer(talent, _amount - resolverShare); // talent payout

        released += _amount;
        resetVotes(RELEASE, _token, _amount);
        emit Released(msg.sender, talent, _token, _amount, _note);
    }

    /// @notice Token balance for specified ERC20
    /// @param _token ERC20 address
    /// @return Amount of tokens in contract
    function balanceOf(address _token) external view returns (uint256) {
        if (_token == address(0)) {
            return address(this).balance;
        }
        return IERC20(_token).balanceOf(address(this));
    }

    function calcShare(uint256 _amount) internal view returns (uint256) {
        return (_amount / 10_000) * fee;
    }
}