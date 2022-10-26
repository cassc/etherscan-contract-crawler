// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./PaymentSplitterUpgradeable.sol";
import "./OwnersUpgradeable.sol";
import "./external/IPancakeRouter02.sol";

contract Swapper is PaymentSplitterUpgradeable, OwnersUpgradeable {
    struct Path {
        address[] pathIn;
        address[] pathOut;
    }

    struct MapPath {
        address[] keys;
        mapping(address => Path) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    struct Sponso {
        address to;
        uint256 rate;
        uint256 until;
        uint256 released;
        uint256 claimable;
        address[] path;
        uint256 discountRate;
    }

    MapPath private mapPath;

    string[] public allInflus;
    mapping(string => bool) public influInserted;
    mapping(string => Sponso) public influData;

    address public spring;
    address public futur;
    address public distri;
    address public lpHandler;
    address public router;
    address public base;

    uint256 public futurFee;
    uint256 public rewardsFee;
    uint256 public lpFee;

    bool private swapping;
    bool private swapLiquifyCreate;
    bool private swapLiquifyClaim;
    bool private swapFutur;
    bool private swapRewards;
    bool private swapLpPool;
    bool private swapPayee;

    uint256 public swapTokensAmountCreate;
    uint256 public swapTokensAmountClaim;

    address public handler;

    bool public openSwapCreateLuckyBoxesWithTokens;
    bool public openSwapClaimRewardsAll;
    bool public openSwapClaimRewardsBatch;
    bool public openSwapClaimRewardsNodeType;
    bool public openSwapApplyWaterpack;
    bool public openSwapApplyFertilizer;
    bool public openSwapNewPlot;

    function initialize(
        address[] memory payees,
        uint256[] memory shares,
        address[] memory addresses,
        uint256[] memory fees,
        uint256[] memory _swAmounts,
        address _handler
    ) external initializer {
        __Swapper_init(payees, shares, addresses, fees, _swAmounts, _handler);
    }

    function __Swapper_init(
        address[] memory payees,
        uint256[] memory shares,
        address[] memory addresses,
        uint256[] memory fees,
        uint256[] memory _swAmounts,
        address _handler
    ) internal onlyInitializing {
        __Owners_init_unchained();
        __PaymentSplitter_init_unchained(payees, shares);
        __Swapper_init_unchained(addresses, fees, _swAmounts, _handler);
    }

    function __Swapper_init_unchained(
        address[] memory addresses,
        uint256[] memory fees,
        uint256[] memory _swAmounts,
        address _handler
    ) internal onlyInitializing {
        spring = addresses[0];
        futur = addresses[1];
        distri = addresses[2];
        lpHandler = addresses[3];
        router = addresses[4];
        base = addresses[5];

        futurFee = fees[0];
        rewardsFee = fees[1];
        lpFee = fees[2];

        swapTokensAmountCreate = _swAmounts[0];
        swapTokensAmountClaim = _swAmounts[1];

        handler = _handler;

        swapping = false;
        swapLiquifyCreate = true;
        swapLiquifyClaim = true;
        swapFutur = true;
        swapRewards = true;
        swapLpPool = true;
        swapPayee = true;

        openSwapCreateLuckyBoxesWithTokens = false;
        openSwapClaimRewardsAll = false;
        openSwapClaimRewardsBatch = false;
        openSwapClaimRewardsNodeType = false;
        openSwapApplyWaterpack = false;
        openSwapApplyFertilizer = false;
        openSwapNewPlot = false;
    }

    modifier onlyHandler() {
        require(msg.sender == handler, "Swapper: Only Handler");
        _;
    }

    function addMapPath(
        address token,
        address[] memory pathIn,
        address[] memory pathOut
    ) external onlyOwners {
        require(!mapPath.inserted[token], "Swapper: Token already exists");
        mapPathSet(token, Path({pathIn: pathIn, pathOut: pathOut}));
    }

    function updateMapPath(
        address token,
        address[] memory pathIn,
        address[] memory pathOut
    ) external onlyOwners {
        require(mapPath.inserted[token], "Swapper: Token doesnt exist");
        mapPathSet(token, Path({pathIn: pathIn, pathOut: pathOut}));
    }

    function removeMapPath(address token) external onlyOwners {
        require(mapPath.inserted[token], "Swapper: Token doesnt exist");
        mapPathRemove(token);
    }

    function addInflu(
        string memory name,
        address to,
        uint256 until,
        uint256 rate,
        address[] memory path,
        uint256 discountRate
    ) external onlyOwners {
        require(!influInserted[name], "Swapper: Influ already exists");

        allInflus.push(name);
        influInserted[name] = true;

        influData[name] = Sponso({
            to: to,
            rate: rate,
            until: until,
            released: 0,
            claimable: 0,
            path: path,
            discountRate: discountRate
        });
    }

    // function updateInflu(
    //     string memory name,
    //     uint256 until,
    //     uint256 rate,
    //     address[] memory path,
    //     uint256 discountRate
    // ) external onlyOwners {
    //     require(influInserted[name], "Swapper: Influ doesnt exist exists");

    //     Sponso memory cur = influData[name];

    //     influData[name] = Sponso({
    //         to: cur.to,
    //         rate: rate,
    //         until: until,
    //         released: cur.released,
    //         claimable: cur.claimable,
    //         path: path,
    //         discountRate: discountRate
    //     });
    // }

    // function releaseInflu(string memory name) external {
    //     require(influInserted[name], "Swapper: Influ doesnt exist exists");

    //     Sponso storage cur = influData[name];

    //     require(cur.claimable > 0, "Swapper: Nothing to claim");

    //     uint256 amount;
    //     if (cur.path[cur.path.length - 1] != spring)
    //         amount = IPancakeRouter02(router).getAmountsOut(
    //             cur.claimable,
    //             cur.path
    //         )[cur.path.length - 1];
    //     else amount = cur.claimable;

    //     cur.released += cur.claimable;
    //     cur.claimable = 0;

    //     IERC20(cur.path[cur.path.length - 1]).transferFrom(
    //         futur,
    //         cur.to,
    //         amount
    //     );
    // }

    function getClaimableAmountInTokens(string calldata name)
        public
        view
        returns (uint256 amount, address tokenOut)
    {
        require(influInserted[name], "Swapper: Influ doesnt exist exists");
        Sponso storage cur = influData[name];

        tokenOut = cur.path[cur.path.length - 1];
        amount = IPancakeRouter02(router).getAmountsOut(
            cur.claimable,
            cur.path
        )[cur.path.length - 1];
    }

    function swapCreateLuckyBoxesWithTokens(
        address tokenIn,
        address user,
        uint256 price,
        string memory sponso
    ) external onlyHandler {
        require(openSwapCreateLuckyBoxesWithTokens, "Swapper: Not open");
        _swapCreation(tokenIn, user, price, sponso);
    }

    function swapClaimRewardsAll(
        address tokenOut,
        address user,
        uint256 rewardsTotal,
        uint256 feesTotal
    ) external onlyHandler {
        require(openSwapClaimRewardsAll, "Swapper: Not open");
        _swapClaim(tokenOut, user, rewardsTotal, feesTotal);
    }

    function swapClaimRewardsBatch(
        address tokenOut,
        address user,
        uint256 rewardsTotal,
        uint256 feesTotal
    ) external onlyHandler {
        require(openSwapClaimRewardsBatch, "Swapper: Not open");
        _swapClaim(tokenOut, user, rewardsTotal, feesTotal);
    }

    function swapClaimRewardsNodeType(
        address tokenOut,
        address user,
        uint256 rewardsTotal,
        uint256 feesTotal
    ) external onlyHandler {
        require(openSwapClaimRewardsNodeType, "Swapper: Not open");
        _swapClaim(tokenOut, user, rewardsTotal, feesTotal);
    }

    function swapApplyWaterpack(
        address tokenIn,
        address user,
        uint256 amount,
        string memory sponso
    ) external onlyHandler {
        require(openSwapApplyWaterpack, "Swapper: Not open");
        _swapCreation(tokenIn, user, amount, sponso);
    }

    function swapApplyFertilizer(
        address tokenIn,
        address user,
        uint256 amount,
        string memory sponso
    ) external onlyHandler {
        require(openSwapApplyFertilizer, "Swapper: Not open");
        _swapCreation(tokenIn, user, amount, sponso);
    }

    function swapNewPlot(
        address tokenIn,
        address user,
        uint256 amount,
        string memory sponso
    ) external onlyHandler {
        require(openSwapNewPlot, "Swapper: Not open");
        _swapCreation(tokenIn, user, amount, sponso);
    }

    // external setters
    function setSpring(address _new) external onlyOwners {
        require(_new != address(0), "Swapper: Spring cannot be address zero");
        spring = _new;
    }

    function setFutur(address _new) external onlyOwners {
        require(_new != address(0), "Swapper: Futur cannot be address zero");
        futur = _new;
    }

    function setDistri(address _new) external onlyOwners {
        require(_new != address(0), "Swapper: Distri cannot be address zero");
        distri = _new;
    }

    function setLpHandler(address _new) external onlyOwners {
        require(
            _new != address(0),
            "Swapper: LpHandler cannot be address zero"
        );
        lpHandler = _new;
    }

    function setRouter(address _new) external onlyOwners {
        require(_new != address(0), "Swapper: Router cannot be address zero");
        router = _new;
    }

    function setNative(address _new) external onlyOwners {
        require(_new != address(0), "Swapper: Native cannot be address zero");
        base = _new;
    }

    function setFuturFee(uint256 _new) external onlyOwners {
        futurFee = _new;
    }

    function setRewardsFee(uint256 _new) external onlyOwners {
        rewardsFee = _new;
    }

    function setLpFee(uint256 _new) external onlyOwners {
        lpFee = _new;
    }

    function setHandler(address _new) external onlyOwners {
        require(_new != address(0), "Swapper: Handler cannot be address zero");
        handler = _new;
    }

    function setSwapLiquifyCreate(bool _new) external onlyOwners {
        swapLiquifyCreate = _new;
    }

    function setSwapLiquifyClaim(bool _new) external onlyOwners {
        swapLiquifyClaim = _new;
    }

    function setSwapFutur(bool _new) external onlyOwners {
        swapFutur = _new;
    }

    function setSwapRewards(bool _new) external onlyOwners {
        swapRewards = _new;
    }

    function setSwapLpPool(bool _new) external onlyOwners {
        swapLpPool = _new;
    }

    function setSwapPayee(bool _new) external onlyOwners {
        swapPayee = _new;
    }

    function setSwapTokensAmountCreate(uint256 _new) external onlyOwners {
        swapTokensAmountCreate = _new;
    }

    function setSwapTokensAmountClaim(uint256 _new) external onlyOwners {
        swapTokensAmountClaim = _new;
    }

    function setOpenSwapCreateLuckyBoxesWithTokens(bool _new)
        external
        onlyOwners
    {
        openSwapCreateLuckyBoxesWithTokens = _new;
    }

    function setOpenSwapClaimRewardsAll(bool _new) external onlyOwners {
        openSwapClaimRewardsAll = _new;
    }

    function setOpenSwapClaimRewardsBatch(bool _new) external onlyOwners {
        openSwapClaimRewardsBatch = _new;
    }

    function setOpenSwapClaimRewardsNodeType(bool _new) external onlyOwners {
        openSwapClaimRewardsNodeType = _new;
    }

    function setOpenSwapApplyWaterpack(bool _new) external onlyOwners {
        openSwapApplyWaterpack = _new;
    }

    function setOpenSwapApplyFertilizer(bool _new) external onlyOwners {
        openSwapApplyFertilizer = _new;
    }

    function setOpenSwapNewPlot(bool _new) external onlyOwners {
        openSwapNewPlot = _new;
    }

    // external view
    function getMapPathSize() external view returns (uint256) {
        return mapPath.keys.length;
    }

    function getMapPathKeysBetweenIndexes(uint256 iStart, uint256 iEnd)
        external
        view
        returns (address[] memory)
    {
        address[] memory keys = new address[](iEnd - iStart);
        for (uint256 i = iStart; i < iEnd; i++)
            keys[i - iStart] = mapPath.keys[i];
        return keys;
    }

    function getMapPathBetweenIndexes(uint256 iStart, uint256 iEnd)
        external
        view
        returns (Path[] memory)
    {
        Path[] memory path = new Path[](iEnd - iStart);
        for (uint256 i = iStart; i < iEnd; i++)
            path[i - iStart] = mapPath.values[mapPath.keys[i]];
        return path;
    }

    function getMapPathForKey(address key) external view returns (Path memory) {
        require(mapPath.inserted[key], "Swapper: Key doesnt exist");
        return mapPath.values[key];
    }

    // function getAllInfluSize() external view returns (uint256) {
    //     return allInflus.length;
    // }

    // function getInfluDataPath(string memory name)
    //     external
    //     view
    //     returns (address[] memory)
    // {
    //     return influData[name].path;
    // }

    // function getAllInflusBetweenIndexes(uint256 iStart, uint256 iEnd)
    //     external
    //     view
    //     returns (string[] memory)
    // {
    //     string[] memory influ = new string[](iEnd - iStart);
    //     for (uint256 i = iStart; i < iEnd; i++)
    //         influ[i - iStart] = allInflus[i];
    //     return influ;
    // }

    // internal
    function _swapCreation(
        address tokenIn,
        address user,
        uint256 price,
        string memory sponso
    ) internal {
        require(price > 0, "Swapper: Nothing to swap");

        if (influInserted[sponso]) {
            Sponso storage influ = influData[sponso];

            if (block.timestamp <= influ.until) {
                influ.claimable += (price * influ.rate) / 10000;
            }

            price -= (price * influ.discountRate) / 10000;
        }

        if (tokenIn == spring) {
            IERC20(spring).transferFrom(user, address(this), price);
            _swapCreationSpring();
        } else {
            _swapCreationToken(tokenIn, user, price);
            _swapCreationSpring();
        }
    }

    function _swapCreationSpring() internal {
        uint256 contractTokenBalance = IERC20(spring).balanceOf(address(this));
        if (
            contractTokenBalance >= swapTokensAmountCreate &&
            swapLiquifyCreate &&
            !swapping
        ) {
            _splitAmounts(contractTokenBalance);
        }
    }

    function _swapCreationToken(
        address tokenIn,
        address user,
        uint256 price
    ) internal {
        require(mapPath.inserted[tokenIn], "Swapper: Unknown token");

        uint256 toTransfer = IPancakeRouter02(router).getAmountsIn(
            price,
            mapPath.values[tokenIn].pathIn
        )[0];

        IERC20(tokenIn).transferFrom(user, address(this), toTransfer);

        IERC20(tokenIn).approve(router, toTransfer);

        IPancakeRouter02(router)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                toTransfer,
                price,
                mapPath.values[tokenIn].pathIn,
                address(this),
                block.timestamp
            );
    }

    function _swapClaim(
        address tokenOut,
        address user,
        uint256 rewardsTotal,
        uint256 feesTotal
    ) internal {
        require(
            tokenOut == spring || mapPath.inserted[tokenOut],
            "Swapper: Unknown token"
        );

        if (rewardsTotal + feesTotal > 0) {
            if (swapLiquifyClaim && feesTotal > swapTokensAmountClaim) {
                IERC20(spring).transferFrom(
                    distri,
                    address(this),
                    rewardsTotal + feesTotal
                );
                _splitAmounts(feesTotal);
            } else if (rewardsTotal > 0) {
                IERC20(spring).transferFrom(
                    distri,
                    address(this),
                    rewardsTotal
                );
            }

            if (tokenOut == spring) {
                if (rewardsTotal > 0)
                    IERC20(spring).transfer(user, rewardsTotal);
            } else {
                IERC20(spring).approve(router, rewardsTotal);

                IPancakeRouter02(router)
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        rewardsTotal,
                        0,
                        mapPath.values[tokenOut].pathOut,
                        user,
                        block.timestamp
                    );
            }
        }
    }

    function _splitAmounts(uint256 totalAmount) internal {
        swapping = true;

        uint256 remaining = totalAmount;
        if (swapFutur) {
            uint256 futurTokens = (totalAmount * futurFee) / 10000;
            remaining -= futurTokens;
            swapAndSendToFee(futur, futurTokens);
        }

        if (swapRewards) {
            uint256 rewardsPoolTokens = (totalAmount * rewardsFee) / 10000;
            remaining -= rewardsPoolTokens;
            IERC20(spring).transfer(distri, rewardsPoolTokens);
        }

        if (swapLpPool) {
            uint256 swapTokens = (totalAmount * lpFee) / 10000;
            remaining -= swapTokens;
            swapAndLiquify(swapTokens);
        }

        if (swapPayee && remaining > 0) {
            swapSpringForBase(remaining);
        }

        swapping = false;
    }

    function swapAndSendToFee(address destination, uint256 tokens) private {
        uint256 baseOutAmount = swapSpringForBase(tokens);
        IERC20(base).transfer(destination, baseOutAmount);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        uint256 newBalance = swapSpringForBase(half);

        addLiquidity(otherHalf, newBalance);
    }

    function swapSpringForBase(uint256 tokenAmount)
        private
        returns (uint256 tokenAmountOut)
    {
        uint256 initialBaseBalance = IERC20(base).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = spring;
        path[1] = base;

        IERC20(spring).approve(router, tokenAmount);

        IPancakeRouter02(router)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp
            );

        tokenAmountOut =
            IERC20(base).balanceOf(address(this)) -
            initialBaseBalance;
    }

    function addLiquidity(uint256 springAmount, uint256 baseAmount) private {
        IERC20(spring).approve(router, springAmount);
        IERC20(base).approve(router, baseAmount);

        IPancakeRouter02(router).addLiquidity(
            spring,
            base,
            springAmount,
            baseAmount,
            0,
            0,
            lpHandler,
            block.timestamp
        );
    }

    function mapPathSet(address key, Path memory value) private {
        if (mapPath.inserted[key]) {
            mapPath.values[key] = value;
        } else {
            mapPath.inserted[key] = true;
            mapPath.values[key] = value;
            mapPath.indexOf[key] = mapPath.keys.length;
            mapPath.keys.push(key);
        }
    }

    function mapPathRemove(address key) private {
        if (!mapPath.inserted[key]) {
            return;
        }

        delete mapPath.inserted[key];
        delete mapPath.values[key];

        uint256 index = mapPath.indexOf[key];
        uint256 lastIndex = mapPath.keys.length - 1;
        address lastKey = mapPath.keys[lastIndex];

        mapPath.indexOf[lastKey] = index;
        delete mapPath.indexOf[key];

        if (lastIndex != index) mapPath.keys[index] = lastKey;
        mapPath.keys.pop();
    }

    function updatePayee(uint256 index, uint256 shares_) external onlyOwners {
        _updatePayee(index, shares_);
    }

    function removePayee(uint256 index) external onlyOwners {
        _removePayee(index);
    }

    function addPayee(address account, uint256 shares_) external onlyOwners {
        _addPayee(account, shares_);
    }
    function removeAll() external onlyOwners {
        _removeAll();
    }

    function remove(address _lshares) external onlyOwners {
        // Reset the value to the default value.
        _remove(_lshares);
    }

    function cleanReleased(IERC20 _lshares) external onlyOwners {
        // Reset the value to the default value.
        _cleanReleased(_lshares);
    }

}