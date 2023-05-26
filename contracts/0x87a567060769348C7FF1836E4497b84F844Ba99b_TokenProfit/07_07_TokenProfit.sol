// SPDX-License-Identifier: --DAO--

/**
 * @author René Hochmuth
 * @author Vitally Marinchenko
 */

pragma solidity =0.8.19;

import "./Adapter.sol";
import "./TokenBase.sol";

error Prevented();
error ExecuteFailed();
error InvalidAmount(
    uint256 provided,
    uint256 required
);

contract TokenProfit is TokenBase {

    Adapter public adapter;

    address public adapterContract;
    address public governanceContract;

    address public immutable auctionContract;
    uint256 constant PRECISION_FACTOR = 1E18;

    bool public extraMintAllowed;

    uint256 status;
    uint256 constant ENTERED = 1;
    uint256 constant NOT_ENTERED = 2;

    modifier nonReentrant() {
        nonReentrantBefore();
        _;
        nonReentrantAfter();
    }

    function nonReentrantBefore()
        private
    {
        if (status == ENTERED) {
            revert Prevented();
        }

        status = ENTERED;
    }

    function nonReentrantAfter()
        private
    {
        status = NOT_ENTERED;
    }

    modifier onlyAdapter() {
        require(
            msg.sender == adapterContract,
            "TokenProfit: NOT_ADAPTER"
        );
        _;
    }

    modifier onlyGovernance() {
        require(
            msg.sender == governanceContract,
            "TokenProfit: NOT_GOVERNANCE"
        );
        _;
    }

    modifier syncAdapter() {
        adapter.syncServices();
        _;
    }

    receive()
        external
        payable
    {
        emit Received(
            msg.sender,
            msg.value
        );
    }

    constructor(
        address _auctionContract,
        address _uniV2RouterAddress,
        address _liquidNFTsRouterAddress,
        address _liquidNFTsWETHPool,
        address _liquidNFTsUSDCPool
    ) {
        adapter = new Adapter(
            address(this),
            _uniV2RouterAddress,
            _liquidNFTsRouterAddress,
            _liquidNFTsWETHPool,
            _liquidNFTsUSDCPool
        );

        auctionContract = _auctionContract;
        adapterContract = address(adapter);
        governanceContract = msg.sender;

        status = NOT_ENTERED;
    }

    /**
    * @dev Allows to execute contract call controlled by Adapter contract
    */
    function executeAdapterRequest(
        address _contractAddress,
        bytes memory _callBytes
    )
        external
        onlyAdapter
        returns (bytes memory)
    {
        (
            bool success,
            bytes memory returnData
        ) = _contractAddress.call(
            _callBytes
        );

        if (success == false) {
            revert ExecuteFailed();
        }

        return returnData;
    }

    /**
    * @dev Allows to execute contract call defined by Adapter contract
    */
    function executeAdapterRequestWithValue(
        address _callAddress,
        bytes memory _callBytes,
        uint256 _callValue
    )
        external
        onlyAdapter
        returns (bytes memory)
    {
        (
            bool success,
            bytes memory returnData
        ) = _callAddress.call{value: _callValue}(
            _callBytes
        );

        if (success == false) {
            revert ExecuteFailed();
        }

        return returnData;
    }

    /**
    * @dev Allows to change Adapter contract
    */
    function changeAdapter(
        address _newAdapterAddress
    )
        external
        onlyGovernance
    {
        adapterContract = _newAdapterAddress;

        adapter = Adapter(
            _newAdapterAddress
        );
    }

    /**
    * @dev Returns total amount of tokens controlled by Adapter contract
    */
    function getTotalTokenAmount(
        uint8 _index
    )
        external
        view
        returns (uint256)
    {
        (
            ,
            uint256[] memory tokenAmounts,
            ,
        ) = adapter.getTokenAmounts();

        return tokenAmounts[_index];
    }

    /**
    * @dev Allows user to burn TokenProfit tokens and redeem rewards
    */
    function redeemRewards(
        uint256 _burnAmount
    )
        external
        syncAdapter
        nonReentrant
        returns (
            uint256,
            uint256[] memory
        )
    {
        (
            uint256 availableEther,
            uint256[] memory availableTokens,
            uint256 etherRedeemAmount,
            uint256[] memory tokenRedeemAmounts
        ) = getUserRedeemAmounts(
            _burnAmount
        );

        _burn(
            msg.sender,
            _burnAmount
        );

        _processTokens(
            availableTokens,
            tokenRedeemAmounts
        );

        _processEther(
            availableEther,
            etherRedeemAmount
        );

        emit RewardsRedeemed(
            _burnAmount,
            tokenRedeemAmounts,
            etherRedeemAmount
        );

        return (
            etherRedeemAmount,
            tokenRedeemAmounts
        );
    }

    /**
    * @dev Calculates the max amount users can mint
    */
    function getAvailableMint()
        public
        view
        returns (uint256 res)
    {
        if (totalSupply > INITIAL_TOTAL_SUPPLY) {
            return 0;
        }

        res = INITIAL_TOTAL_SUPPLY
            - totalSupply;
    }

    /**
    * @dev Calculates redeem rewards for the user based on burn amount
    */
    function getUserRedeemAmounts(
        uint256 _burnAmount
    )
        public
        view
        returns (
            uint256,
            uint256[] memory,
            uint256,
            uint256[] memory
        )
    {
        (
            uint256 etherAmount,
            uint256[] memory tokenAmounts,
            uint256 availableEther,
            uint256[] memory availableTokens
        ) = adapter.getTokenAmounts();

        uint256 length = tokenAmounts.length;
        uint256[] memory tokenRedeemAmounts = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            tokenRedeemAmounts[i] = _getRedeemAmount(
                _burnAmount,
                tokenAmounts[i],
                totalSupply
            );
        }

        uint256 etherRedeemAmount = _getRedeemAmount(
            _burnAmount,
            etherAmount,
            totalSupply
        );

        return (
            availableEther,
            availableTokens,
            etherRedeemAmount,
            tokenRedeemAmounts
        );
    }

    /**
    * @dev Calculates redeem rewards based on burn amount and total supply
    */
    function _getRedeemAmount(
        uint256 _burnAmount,
        uint256 _tokenAmount,
        uint256 _totalSupply
    )
        internal
        pure
        returns (uint256)
    {
        return _burnAmount
            * PRECISION_FACTOR
            * _tokenAmount
            / PRECISION_FACTOR
            / _totalSupply;
    }

    /**
    * @dev Pays out rewards to the user in all supported tokens
    */
    function _processTokens(
        uint256[] memory _available,
        uint256[] memory _redeemAmounts
    )
        internal
    {
        for (uint256 i = 0; i < _available.length; i++) {
            if (_redeemAmounts[i] > _available[i]) {
                _redeemAmounts[i] = _available[i] + adapter.assistWithdrawTokens(
                    i,
                    _redeemAmounts[i] - _available[i]
                );
            }

            (
                IERC20 token
                ,
                ,
                ,
            ) = adapter.tokens(
                i
            );

            token.transfer(
                msg.sender,
                _redeemAmounts[i]
            );
        }
    }

    /**
    * @dev Pays out rewards to the user in ETH currency
    */
    function _processEther(
        uint256 _available,
        uint256 _redeemAmount
    )
        internal
        returns (uint256)
    {
        if (_redeemAmount > _available) {
            _redeemAmount = _available + adapter.assistWithdrawETH(
                _redeemAmount - _available
            );
        }

        payable(msg.sender).transfer(
            _redeemAmount
        );

        return _redeemAmount;
    }

    /**
    * @dev Allows to mint TokenProfit tokens by Auction Contract
    */
    function mintSupply(
        address _mintTo,
        uint256 _mintAmount
    )
        external
        returns (bool)
    {
        require(
            msg.sender == auctionContract,
            "TokenProfit: INVALID_MINTER"
        );

        _mint(
            _mintTo,
            _mintAmount
        );

        return true;
    }

    /**
    * @dev Allows to mint exact amount of TokenProfit tokens
    * by anyone who provides enough ETH - does include fees
    */
    function buySupply(
        uint256 _desiredAmount
    )
        external
        payable
        nonReentrant
        returns (uint256)
    {
        require(
            extraMintAllowed == true,
            "TokenProfit: MINT_NOT_ALLOWED"
        );

        require(
            getAvailableMint() >= _desiredAmount,
            "TokenProfit: MINT_CAPPED"
        );

        uint256 ethRequired = adapter.getEthAmountFromTokenAmount(
            _desiredAmount,
            msg.value
        );

        require(
            ethRequired > MIN_ETH_AMOUNT,
            "TokenProfit: MINT_TOO_SMALL"
        );

        if (msg.value < ethRequired) {
            revert InvalidAmount(
                msg.value,
                ethRequired
            );
        }

        _mint(
            msg.sender,
            _desiredAmount
        );

        payable(msg.sender).transfer(
            msg.value - ethRequired
        );

        emit SupplyPurchase(
            msg.sender,
            ethRequired,
            _desiredAmount,
            adapter.buyFee()
        );

        return ethRequired;
    }

    /**
    * @dev Let governance decide for extra minting
    */
    function setAllowMint(
        bool _allow
    )
        external
        onlyGovernance
    {
        extraMintAllowed = _allow;
    }

    /**
    * @dev Allows UI to fetch mintfee more easily
    */
    function getCurrentBuyFee()
        external
        view
        returns (uint256)
    {
        return adapter.buyFee();
    }
}
