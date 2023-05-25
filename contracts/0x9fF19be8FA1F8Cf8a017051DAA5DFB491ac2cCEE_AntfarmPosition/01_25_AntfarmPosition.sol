// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "../interfaces/IAntfarmPair.sol";
import "../interfaces/IAntfarmPosition.sol";
import "../interfaces/IAntfarmFactory.sol";
import "../interfaces/IWETH.sol";
import "../libraries/TransferHelper.sol";
import "../utils/AntfarmPositionErrors.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title NFT positions
/// @notice Wraps Antfarm positions in ERC721
contract AntfarmPosition is IAntfarmPosition, ERC721Enumerable {
    address public immutable factory;
    address public immutable WETH;
    address public immutable antfarmToken;

    using Counters for Counters.Counter;
    Counters.Counter private _positionIds;

    mapping(uint256 => Position) public positions;

    modifier ensure(uint256 deadline) {
        if (deadline < block.timestamp) revert Expired();
        _;
    }

    modifier isOwner(uint256 positionId) {
        // ownerOf will revert if positionId isn't a position owned
        if (msg.sender != ownerOf(positionId)) revert NotOwner();
        _;
    }

    modifier isOwnerOrAllowed(uint256 positionId) {
        // check if sender is owner or delegate, used to claim dividends
        if (
            msg.sender != ownerOf(positionId) &&
            msg.sender != positions[positionId].delegate
        ) revert NotAllowed();
        _;
    }

    constructor(
        address _factory,
        address _WETH,
        address _antfarmToken
    ) ERC721("Antfarm Positions", "ANTPOS") {
        require(_factory != address(0), "NULL_FACTORY_ADDRESS");
        require(_WETH != address(0), "NULL_WETH_ADDRESS");
        require(_antfarmToken != address(0), "NULL_ATF_ADDRESS");
        factory = _factory;
        WETH = _WETH;
        antfarmToken = _antfarmToken;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    /// @notice Create a position in an AntFarmPair. Create an NFT for this position
    /// @param tokenA Token of the AntfarmPair
    /// @param tokenB Token of the AntfarmPair
    /// @param fee Associated fee to the AntFarmPair
    /// @param amountADesired tokenA amount to be added as liquidity
    /// @param amountBDesired tokenB amount to be added as liquidity
    /// @param amountAMin Minimum tokenA amount to be added as liquidity
    /// @param amountBMin Minimum tokenB amount to be added as liquidity
    /// @param to The address to be used to mint the NFT position
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @return amountA tokenA amount added to the AntfarmPair as liquidity
    /// @return amountB tokenB amount added to the AntfarmPair as liquidity
    /// @return liquidity Liquidity minted
    function createPosition(
        address tokenA,
        address tokenB,
        uint16 fee,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        virtual
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        address pair = pairFor(tokenA, tokenB, fee);
        _positionIds.increment();
        positions[_positionIds.current()] = Position(
            pair,
            address(0),
            false,
            0,
            0
        );

        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            fee,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );

        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);

        liquidity = IAntfarmPair(pair).mint(
            address(this),
            _positionIds.current()
        );

        _safeMint(to, _positionIds.current());
        emit Create(
            to,
            _positionIds.current(),
            pair,
            amountA,
            amountB,
            liquidity
        );
    }

    /// @notice Create a position in an AntFarmPair using WETH. Create an NFT for this position
    /// @param token Token of the AntfarmPair
    /// @param fee associated fee to the AntFarmPair
    /// @param amountTokenDesired token amount to be added as liquidity
    /// @param amountTokenMin Minimum token amount to be added as liquidity
    /// @param amountETHMin Minimum ETH amount to be added as liquidity
    /// @param to The address to be used to mint the NFT position
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @return amountToken token amount added to the AntfarmPair as liquidity
    /// @return amountETH ETH amount added to the AntfarmPair as liquidity
    /// @return liquidity Liquidity minted
    function createPositionETH(
        address token,
        uint16 fee,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        _positionIds.increment();
        address pair = pairFor(token, WETH, fee);
        positions[_positionIds.current()] = Position(
            pair,
            address(0),
            false,
            0,
            0
        );

        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            fee,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );

        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));

        liquidity = IAntfarmPair(pair).mint(
            address(this),
            _positionIds.current()
        );

        _safeMint(to, _positionIds.current());

        // refund dust ETH, if any
        if (msg.value > amountETH)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);

        emit Create(
            to,
            _positionIds.current(),
            pair,
            amountToken,
            amountETH,
            liquidity
        );
    }

    /// @notice Increase liquidity for an existing position
    /// @param params Predefined parameters struct
    // @param tokenA Base token from the AntfarmPair
    // @param tokenB Quote token from the AntfarmPair
    // @param fee Associated fee to the AntFarmPair
    // @param amountADesired tokenA amount to be added as liquidity
    // @param amountBDesired tokenB amount to be added as liquidity
    // @param amountAMin Minimum tokenA amount to be added as liquidity
    // @param amountBMin Minimum tokenB amount to be added as liquidity
    // @param deadline Unix timestamp after which the transaction will revert
    // @param positionId position ID
    /// @return amountA tokenA amount added to the AntfarmPair as liquidity
    /// @return amountB tokenB amount added to the AntfarmPair as liquidity
    /// @return liquidity Liquidity minted
    function increasePosition(IncreasePositionParams calldata params)
        external
        virtual
        isOwnerOrAllowed(params.positionId)
        ensure(params.deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(
            params.tokenA,
            params.tokenB,
            params.fee,
            params.amountADesired,
            params.amountBDesired,
            params.amountAMin,
            params.amountBMin
        );

        address pair = pairFor(params.tokenA, params.tokenB, params.fee);

        TransferHelper.safeTransferFrom(
            params.tokenA,
            msg.sender,
            pair,
            amountA
        );
        TransferHelper.safeTransferFrom(
            params.tokenB,
            msg.sender,
            pair,
            amountB
        );

        liquidity = IAntfarmPair(pair).mint(address(this), params.positionId);

        emit Increase(
            ownerOf(params.positionId),
            params.positionId,
            pair,
            amountA,
            amountB,
            liquidity
        );
    }

    /// @notice Increase liquidity for an existing position for an ETH Antfarmpair
    /// @param params Predefined parameters struct
    // @param token Token from the AntfarmPair
    // @param fee Associated fee to the AntFarmPair
    // @param amountTokenDesired Token amount to be added as liquidity
    // @param amountTokenMin Minimum token amount to be added as liquidity
    // @param amountETHMin Minimum ETH amount to be added as liquidity
    // @param deadline Unix timestamp after which the transaction will revert
    // @param positionId Position ID
    /// @return amountToken Token amount added to the AntfarmPair as liquidity
    /// @return amountETH ETH amount added to the AntfarmPair as liquidity
    /// @return liquidity Liquidity minted
    function increasePositionETH(IncreasePositionETHParams calldata params)
        external
        payable
        virtual
        isOwnerOrAllowed(params.positionId)
        ensure(params.deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(
            params.token,
            WETH,
            params.fee,
            params.amountTokenDesired,
            msg.value,
            params.amountTokenMin,
            params.amountETHMin
        );

        address pair = pairFor(params.token, WETH, params.fee);

        TransferHelper.safeTransferFrom(
            params.token,
            msg.sender,
            pair,
            amountToken
        );
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));

        liquidity = IAntfarmPair(pair).mint(address(this), params.positionId);
        // refund dust ETH, if any
        if (msg.value > amountETH)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);

        emit Increase(
            ownerOf(params.positionId),
            params.positionId,
            pair,
            amountToken,
            amountETH,
            liquidity
        );
    }

    /// @notice Enable lock option for a position
    /// @param positionId Position ID to enable lock
    /// @param deadline Unix timestamp after which the transaction will revert
    function enableLock(uint256 positionId, uint256 deadline)
        external
        virtual
        isOwner(positionId)
        ensure(deadline)
    {
        if (positions[positionId].enableLock) revert AlreadyAllowed();
        positions[positionId].enableLock = true;
    }

    /// @notice Disable lock option for a position
    /// @param positionId Position ID to enable lock
    /// @param deadline Unix timestamp after which the transaction will revert
    function disableLock(uint256 positionId, uint256 deadline)
        external
        virtual
        isOwner(positionId)
        ensure(deadline)
    {
        if (!positions[positionId].enableLock) revert AlreadyDisallowed();
        if (positions[positionId].lock > block.timestamp) {
            revert LockedLiquidity();
        }
        positions[positionId].enableLock = false;
    }

    /// @notice Lock a position for a custom period
    /// @param locktime Timestamp until liquidity is locked
    /// @param positionId Position ID to enable lock
    /// @param deadline Unix timestamp after which the transaction will revert
    function lockPosition(
        uint32 locktime,
        uint256 positionId,
        uint256 deadline
    ) external virtual isOwner(positionId) ensure(deadline) {
        if (!positions[positionId].enableLock) revert LockNotAllowed();
        if (
            locktime <= block.timestamp ||
            locktime <= positions[positionId].lock
        ) revert WrongLocktime();
        positions[positionId].lock = locktime;

        emit Lock(msg.sender, positionId, positions[positionId].pair, locktime);
    }

    /// @notice Burn a position NFT if it has no liquidity nor claimable dividends
    /// @param positionId Owner postion ID to burn
    function burn(uint256 positionId) external isOwner(positionId) {
        IAntfarmPair pair = IAntfarmPair(positions[positionId].pair);
        if (pair.getPositionLP(address(this), positionId) != 0) {
            revert LiquidityToClaim();
        }
        if (pair.claimableDividends(address(this), positionId) != 0) {
            revert DividendsToClaim();
        }
        emit Burn(msg.sender, positionId);
        _burn(positionId);
    }

    /// @notice Claim dividends for multiple positions
    /// @param positionIds Owner position IDs array to claim
    /// @return claimedAmount Claimed amount from positions given
    function claimDividendGrouped(uint256[] calldata positionIds)
        external
        returns (uint256 claimedAmount)
    {
        uint256 positionsLength = positionIds.length;
        for (uint256 i; i < positionsLength; ++i) {
            claimedAmount = claimedAmount + claimDividend(positionIds[i]);
        }
    }

    function setDelegate(uint256 positionId, address delegate)
        public
        isOwner(positionId)
    {
        positions[positionId].delegate = delegate;
    }

    function setDelegates(uint256[] calldata positionIds, address delegate)
        external
    {
        uint256 numPositions = positionIds.length;

        for (uint256 i; i < numPositions; ++i) {
            setDelegate(positionIds[i], delegate);
        }
    }

    function getPositionsDetails(uint256[] calldata positionIds)
        external
        view
        returns (PositionDetails[] memory)
    {
        PositionDetails[] memory positionsDetails = new PositionDetails[](
            positionIds.length
        );
        for (uint256 i; i < positionIds.length; ++i) {
            positionsDetails[i] = getPositionDetails(positionIds[i]);
        }

        return positionsDetails;
    }

    function getPositionDetails(uint256 positionId)
        public
        view
        returns (PositionDetails memory positionDetails)
    {
        Position memory position = positions[positionId];
        IAntfarmPair pair = IAntfarmPair(position.pair);

        uint256 lp = pair.getPositionLP(address(this), positionId);
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        uint256 positionReserve0 = (lp * reserve0) / pair.totalSupply();
        uint256 positionReserve1 = (lp * reserve1) / pair.totalSupply();

        positionDetails = PositionDetails(
            positionId, // uint256 id;
            ownerOf(positionId), // address owner;
            position.delegate, // address delegate;
            position.pair, // address pair;
            pair.token0(), // address token0;
            pair.token1(), // address token1;
            lp, // uint256 lp;
            positionReserve0, // uint256 reserve0;
            positionReserve1, // uint256 reserve1;
            getDividend(positionId), // uint256 dividend;
            position.claimedAmount, // uint256 cumulatedDividend;
            pair.fee(), // uint16 fee;
            position.enableLock, // bool enableLock;
            position.lock // uint32 lock;
        );
    }

    /// @notice Get dividend for each position given
    /// @param owner Positions's owner
    /// @return uint[] Positions IDs
    /// @return uint[] Dividends
    function getDividendPerPosition(address owner)
        external
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory positionIds = getPositionsIds(owner);
        uint256[] memory dividends = new uint256[](positionIds.length);

        uint256 positionsLength = positionIds.length;
        for (uint256 i; i < positionsLength; ++i) {
            dividends[i] = getDividend(positionIds[i]);
        }

        return (positionIds, dividends);
    }

    /// @notice Decrease LP for a position
    /// @param params Predefined parameters struct
    // @param tokenA Base token from the AntfarmPair
    // @param tokenB Quote token from the AntfarmPair
    // @param fee Associated fee to the AntFarmPair
    // @param liquidity Liquidity to be burned
    // @param amountAMin Minimum tokenA amount to be withdrawn from the position
    // @param amountBMin Minimum tokenB amount to be withdrawn from the position
    // @param to Address owner associated to the position
    // @param deadline Unix timestamp after which the transaction will revert
    // @param positionId Position ID
    /// @return amountA tokenA amount received
    /// @return amountB tokenB amount received
    function decreasePosition(DecreasePositionParams calldata params)
        external
        virtual
        isOwner(params.positionId)
        ensure(params.deadline)
        returns (uint256 amountA, uint256 amountB)
    {
        if (block.timestamp <= positions[params.positionId].lock) {
            revert LockedLiquidity();
        }

        (uint256 amount0, uint256 amount1) = IAntfarmPair(
            pairFor(params.tokenA, params.tokenB, params.fee)
        ).burn(params.to, params.positionId, params.liquidity);
        (address token0, ) = sortTokens(params.tokenA, params.tokenB);
        (amountA, amountB) = params.tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);
        if (amountA < params.amountAMin) revert InsufficientAAmount();
        if (amountB < params.amountBMin) revert InsufficientBAmount();

        emit Decrease(
            msg.sender,
            params.positionId,
            positions[params.positionId].pair,
            amountA,
            amountB,
            params.liquidity
        );
    }

    /// @notice Decrease LP for a position in an AntFarmPair with ETH
    /// @param params Predefined parameters struct
    // @param token Token from the AntfarmPair
    // @param fee Associated fee to the AntFarmPair
    // @param liquidity Liquidity to be burned
    // @param amountTokenMin Minimum token amount to be withdrawn from the position
    // @param amountETHMin Minimum ETH amount to be withdrawn from the position
    // @param to Address owner associated to the position
    // @param deadline Unix timestamp after which the transaction will revert
    // @param positionId Position ID
    /// @return amountToken Token amount received
    /// @return amountETH ETH amount received
    function decreasePositionETH(DecreasePositionETHParams calldata params)
        external
        isOwner(params.positionId)
        ensure(params.deadline)
        returns (uint256 amountToken, uint256 amountETH)
    {
        if (block.timestamp <= positions[params.positionId].lock) {
            revert LockedLiquidity();
        }

        (uint256 amount0, uint256 amount1) = IAntfarmPair(
            pairFor(params.token, WETH, params.fee)
        ).burn(address(this), params.positionId, params.liquidity);
        (address token0, ) = sortTokens(params.token, WETH);
        (amountToken, amountETH) = params.token == token0
            ? (amount0, amount1)
            : (amount1, amount0);
        if (amountToken < params.amountTokenMin) revert InsufficientAAmount();
        if (amountETH < params.amountETHMin) revert InsufficientBAmount();

        TransferHelper.safeTransfer(params.token, params.to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(params.to, amountETH);

        emit Decrease(
            msg.sender,
            params.positionId,
            positions[params.positionId].pair,
            amountToken,
            amountETH,
            params.liquidity
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://metadata.antfarm.finance/positions/metadata/";
    }

    /// @notice Claim dividend for a position
    /// @param positionId Position ID to claim
    /// @return claimedAmount Dividend amount claimed
    function claimDividend(uint256 positionId)
        public
        isOwnerOrAllowed(positionId)
        returns (uint256 claimedAmount)
    {
        IAntfarmPair pair = IAntfarmPair(positions[positionId].pair);
        positions[positionId].claimedAmount += pair.claimableDividends(
            address(this),
            positionId
        );
        claimedAmount = pair.claimDividend(msg.sender, positionId);
        emit Claim(
            ownerOf(positionId),
            positionId,
            positions[positionId].pair,
            claimedAmount
        );
    }

    /// @notice Get all position IDs for an address
    /// @param owner Owner address
    /// @return positionIds Position IDs array associated with the owner address
    function getPositionsIds(address owner)
        public
        view
        returns (uint256[] memory positionIds)
    {
        uint256 balance = balanceOf(owner);
        positionIds = new uint256[](balance);

        for (uint256 i; i < balance; ++i) {
            positionIds[i] = tokenOfOwnerByIndex(owner, i);
        }
    }

    // ADD LIQUIDITY
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint16 fee,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create pair if it doesn't exist
        if (
            IAntfarmFactory(factory).getPair(tokenA, tokenB, fee) == address(0)
        ) {
            IAntfarmFactory(factory).createPair(tokenA, tokenB, fee);
        }
        (uint256 reserveA, uint256 reserveB) = getReserves(tokenA, tokenB, fee);
        if (reserveA == 0 && reserveB == 0) {
            // pool is a new one
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal < amountBMin) revert InsufficientBAmount();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                if (amountAOptimal < amountAMin) revert InsufficientAAmount();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /// @notice Get the dividend of a single position
    /// @param positionId Position ID
    /// @return dividend Dividends owed
    function getDividend(uint256 positionId)
        internal
        view
        returns (uint256 dividend)
    {
        IAntfarmPair pair = IAntfarmPair(positions[positionId].pair);
        dividend = pair.claimableDividends(address(this), positionId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 positionId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, positionId);
        positions[positionId].delegate = address(0);
    }

    // **** LIBRARY FUNCTIONS ADDED INTO THE CONTRACT ****
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        view
        returns (address token0, address token1)
    {
        if (tokenA == tokenB) revert IdenticalAddresses();
        if (tokenA == antfarmToken || tokenB == antfarmToken) {
            (token0, token1) = tokenA == antfarmToken
                ? (antfarmToken, tokenB)
                : (antfarmToken, tokenA);
            if (token1 == address(0)) revert ZeroAddress();
        } else {
            (token0, token1) = tokenA < tokenB
                ? (tokenA, tokenB)
                : (tokenB, tokenA);
            if (token0 == address(0)) revert ZeroAddress();
        }
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address tokenA,
        address tokenB,
        uint16 fee
    ) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encodePacked(
                                    token0,
                                    token1,
                                    fee,
                                    antfarmToken
                                )
                            ),
                            token0 == antfarmToken
                                ? hex"b174de46ec9038ead3d74ed04c79d4885d8e642175833c4da037d5e052492e5b" // AtfPair init code hash
                                : hex"2f47d72b208014a5ba4f32371ac96dd421a39152dcaf104e8232b6c9f1a92280" // Pair init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address tokenA,
        address tokenB,
        uint16 fee
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IAntfarmPair(
            pairFor(tokenA, tokenB, fee)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256) {
        if (amountA == 0) revert InsufficientAmount();
        if (reserveA == 0 || reserveB == 0) revert InsufficientLiquidity();
        return (amountA * reserveB) / reserveA;
    }
}