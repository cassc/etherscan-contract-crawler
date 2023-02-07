// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../interfaces/IBabyPair.sol';
import '../interfaces/IFactory.sol';

contract CalculateRouter is Ownable {
    using SafeMath for uint;

    uint constant FEE_RATIO = 1e6;

    struct Path {
        bool exist;
        IFactory[] factories;
        uint[] fees;
        address[] paths;
    }

    IFactory[] factories;
    address[] middleTokens;
    mapping(address => bool) isMiddleToken;
    mapping(IFactory => uint) fees;
    mapping(address => mapping(address => Path)) fixRouters;

    function checkFactoryExist(IFactory _factory) internal view returns (bool) {
        for (uint i = 0; i < factories.length; i ++) {
            if (address(factories[i]) == address(_factory)) {
                return true;
            }
        }
        return false;
    }

    function addFactory(IFactory _factory, uint _fee) external onlyOwner {
        for (uint i = 0; i < factories.length; i ++) {
            require(address(factories[i]) != address(_factory), "the factory already exists");
        }
        factories.push(_factory);
        fees[_factory] = _fee;
    }

    function delFactory(IFactory _factory) external onlyOwner {
        //the length of factories will not be too big, so the foreach is ok
        //for the delete, we don't want to change the sort of the factories
        //so the easies way is foreach
        IFactory[] memory newFactories = new IFactory[](factories.length);
        uint index = 0;
        for (uint i = 0; i < factories.length; i ++) {
            if (address(factories[i]) != address(_factory)) {
                newFactories[index ++] = factories[i];
            }
        }
        if (index < factories.length) {
            assembly {
                mstore(newFactories, index)
            }
            factories = newFactories;
            delete fees[_factory];
        }
    }

    function addMiddleToken(address _token) external onlyOwner {
        for (uint i = 0; i < middleTokens.length; i ++) {
            require(middleTokens[i] != _token, "already exists");
        }
        middleTokens.push(_token);
        isMiddleToken[_token] = true;
    }

    function delMiddleToken(address _token) external onlyOwner {
        address[] memory newMiddleTokens = new address[](middleTokens.length);
        uint index = 0;
        for (uint i = 0; i < middleTokens.length; i ++) {
            if (middleTokens[i] != _token) {
                newMiddleTokens[index ++] = middleTokens[i];
            }
        }
        if (index < newMiddleTokens.length) {
            assembly {
                mstore(newMiddleTokens, index)
            }
            middleTokens = newMiddleTokens;
        }
        delete isMiddleToken[_token];
    }

    function addFixRouter(address _tokenA, address _tokenB, IFactory[] memory _factories, address[] memory _paths) external onlyOwner {
        require(!fixRouters[_tokenA][_tokenB].exist, "already exists");
        require(_paths.length >= 2 && _factories.length == _paths.length - 1, "illegal param");
        require(_paths[0] == _tokenA && _paths[_paths.length - 1] == _tokenB, "illegal path");
        uint[] memory factoryFees = new uint[](_factories.length);
        for (uint i = 0; i < _factories.length; i ++) {
            require(checkFactoryExist(_factories[i]), "factory not exist");
            factoryFees[i] = fees[_factories[i]];
            require(_factories[i].getPair(_paths[i], _paths[i + 1]) != address(0), "path not exist in factory");
        }
        Path memory path;
        path.factories = _factories;
        path.fees = factoryFees;
        path.paths = _paths;
        path.exist = true;
        fixRouters[_tokenA][_tokenB] = path;
        Path memory reservePath;
        reservePath.factories = new IFactory[](_factories.length);
        reservePath.fees = new uint[](_factories.length);
        reservePath.paths = new address[](_paths.length);
        reservePath.exist = true;
        uint factoryIndex = 0;
        uint pathIndex = 0;
        reservePath.paths[pathIndex ++] = _paths[_paths.length - 1];
        for (uint i = _factories.length; i > 0; i --) {
            reservePath.fees[factoryIndex] = factoryFees[i - 1];
            reservePath.factories[factoryIndex ++] = _factories[i - 1];
            reservePath.paths[pathIndex ++] = _paths[i - 1];
        }
        fixRouters[_tokenB][_tokenA] = reservePath;
    }

    function delFixRouter(address _tokenA, address _tokenB) external onlyOwner {
        delete fixRouters[_tokenA][_tokenB];
        delete fixRouters[_tokenB][_tokenA];
    }

    function getFactory(uint _idx) external view onlyOwner returns (IFactory factory, uint fee) { //only owner can read
        require(_idx < factories.length, "illegal idx");
        factory = factories[_idx];
        fee = fees[factory];
    }

    function getMiddleToken(uint _idx) external view onlyOwner returns (address) { //only owner can read
        require(_idx < middleTokens.length, "illegal idx");
        return middleTokens[_idx];
    }

    function getFixRouter(address _tokenA, address _tokenB) external view onlyOwner returns (Path memory) { //only owner can read
        return fixRouters[_tokenA][_tokenB];
    }

    function middleTokenExist(address _token) external view onlyOwner returns (bool) {
        return isMiddleToken[_token];
    }

    function factoryExist(IFactory _factory) external view onlyOwner returns (bool) {
        for (uint i = 0; i < factories.length; i ++) {
            if(address(factories[i]) == address(_factory)) {
                return true;
            }
        }
        return false;
    }

    struct EndPath {
        IFactory factory;
        address token;
    }

    function getEndPath(address _token) internal view returns (EndPath[] memory paths) {
        paths = new EndPath[](factories.length * middleTokens.length);
        uint pathIndex = 0;
        for (uint i = 0; i < middleTokens.length; i ++) {
            address middleToken = middleTokens[i];
            for (uint j = 0; j < factories.length; j ++) {
                IFactory factory = factories[j];
                if (factory.getPair(_token, middleToken) != address(0)) {
                    paths[pathIndex].factory = factory;
                    paths[pathIndex].token = middleToken;
                    pathIndex ++;
                }
            }
        }
        if (pathIndex < paths.length) {
            assembly {
                mstore(paths, pathIndex)
            }
        }
    }

    struct SwapPath {
        IFactory[] factories;
        uint[] fees;
        address[] path;
    }

    function combionPath(address _tokenA, address _tokenB, EndPath memory leftPath, EndPath memory rightPath, SwapPath[] memory paths, uint pathIndex) internal view returns (uint) {
        Path memory fixPath;
        if (leftPath.token != rightPath.token) {
            fixPath = fixRouters[leftPath.token][rightPath.token];
        }
        IFactory[] memory pathFactories = new IFactory[](2 + fixPath.factories.length);
        uint[] memory pathFees = new uint[](2 + fixPath.factories.length);
        address[] memory pathPath = new address[](2 + fixPath.factories.length + 1);
        uint factoryIndex = 0;
        uint currentPathIndex = 0;
        if (address(leftPath.factory) == address(0)) {
            //paths[pathIndex].path[currentPathIndex ++] = _tokenA;
        } else {
            pathFees[factoryIndex] = fees[leftPath.factory];
            pathFactories[factoryIndex ++] = leftPath.factory;
            pathPath[currentPathIndex ++] = _tokenA;
            pathPath[currentPathIndex ++] = leftPath.token;
        }
        if (fixPath.factories.length > 0) {
            //pathPath[currentPathIndex ++] = fixPath.paths[0];
            for (uint m = 0; m < fixPath.factories.length; m ++) {
                pathFees[factoryIndex] = fixPath.fees[m];
                pathFactories[factoryIndex ++] = fixPath.factories[m];
                pathPath[currentPathIndex ++] = fixPath.paths[m + 1];
            }
        }
        if (address(rightPath.factory) == address(0)) {
            //paths[pathIndex].path[currentPathIndex ++] = _tokenB;
        } else {
            pathFees[factoryIndex] = fees[rightPath.factory];
            pathFactories[factoryIndex ++] = rightPath.factory;
            //paths[pathIndex].path[currentPathIndex ++] = rightPath.token;
            pathPath[currentPathIndex ++] = _tokenB;
        }
        if (factoryIndex < pathFees.length) {
            assembly {
                mstore(pathFees, factoryIndex)
                mstore(pathFactories, factoryIndex)
            }
        }
        if (currentPathIndex < pathPath.length) {
            assembly {
                mstore(pathPath, currentPathIndex)
            }
        }
        paths[pathIndex].factories = pathFactories;
        paths[pathIndex].fees = pathFees;
        paths[pathIndex].path = pathPath;
        bool crycle = false;
        for (uint m = 1; m < paths[pathIndex].path.length - 1; m ++) {
            if (paths[pathIndex].path[m] == _tokenA || paths[pathIndex].path[m] == _tokenB) {
                crycle = true;
                break;
            }
        }
        if (!crycle) {
            pathIndex ++;
        }
        return pathIndex;
    }

    function directPath(address _tokenA, address _tokenB, SwapPath[] memory paths, uint pathIndex) internal view returns(uint) {
        if (isMiddleToken[_tokenA] || isMiddleToken[_tokenB]) {
            return pathIndex;
        }
        for (uint i = 0; i < factories.length; i ++) {
            IFactory factory = factories[i];
            if (factory.getPair(_tokenA, _tokenB) != address(0)) {
                paths[pathIndex].factories = new IFactory[](1);
                paths[pathIndex].factories[0] = factory;
                paths[pathIndex].fees = new uint[](1);
                paths[pathIndex].fees[0] = fees[factory];
                paths[pathIndex].path = new address[](2);
                paths[pathIndex].path[0] = _tokenA; paths[pathIndex].path[1] = _tokenB;
                pathIndex ++;
            }
        }
        return pathIndex;
    }


    function getPath(address _tokenA, address _tokenB) public view returns (SwapPath[] memory paths) {
        require(_tokenA != _tokenB, "illegal token");
        if (fixRouters[_tokenA][_tokenB].exist) {
            paths = new SwapPath[](1);
            paths[0].factories = fixRouters[_tokenA][_tokenB].factories;
            paths[0].fees = fixRouters[_tokenA][_tokenB].fees;
            paths[0].path = fixRouters[_tokenA][_tokenB].paths;
            return paths;
        }
        EndPath[] memory leftPaths = getEndPath(_tokenA);
        EndPath[] memory rightPaths = getEndPath(_tokenB);
        paths = new SwapPath[](leftPaths.length * rightPaths.length + 1);
        uint pathIndex = 0;
        for (uint i = 0; i < leftPaths.length; i ++) {
            EndPath memory leftPath = leftPaths[i];
            if (leftPath.token == _tokenB) {
                //if the left middleToken is the deserved token, we don't neeed to continue
                paths[pathIndex].factories = new IFactory[](1);
                paths[pathIndex].factories[0] = leftPath.factory;
                paths[pathIndex].fees = new uint[](1);
                paths[pathIndex].fees[0] = fees[leftPath.factory];
                paths[pathIndex].path = new address[](2);
                paths[pathIndex].path[0] = _tokenA; paths[pathIndex].path[1] = _tokenB;
                pathIndex ++;
                continue;
            }
            for (uint j = 0; j < rightPaths.length; j ++) {
                EndPath memory rightPath = rightPaths[j];
                if (rightPath.token == _tokenA) {
                    //if the middleToken is the input token, we don't need to deeal the left
                    paths[pathIndex].factories = new IFactory[](1);
                    paths[pathIndex].factories[0] = rightPath.factory;
                    paths[pathIndex].fees = new uint[](1);
                    paths[pathIndex].fees[0] = fees[rightPath.factory];
                    paths[pathIndex].path = new address[](2);
                    paths[pathIndex].path[0] = _tokenA; paths[pathIndex].path[1] = _tokenB;
                    pathIndex ++;
                    continue;
                }
                pathIndex = combionPath(_tokenA, _tokenB, leftPath, rightPath, paths, pathIndex);
            }
        }
        pathIndex = directPath(_tokenA, _tokenB, paths, pathIndex);
        if (pathIndex < paths.length) {
            assembly {
                mstore(paths, pathIndex)
            }
        }
    }

    function getAmountOutWithFee(uint _amountIn, uint _reserveIn, uint _reserveOut, uint _fee) internal pure returns (uint amountOut) {
        assert(_amountIn > 0);
        if (_reserveIn <= 0 || _reserveOut <= 0) return 0;
        uint amountInWithFee = _amountIn.mul(FEE_RATIO.sub(_fee));
        uint numerator = amountInWithFee.mul(_reserveOut);
        uint denominator = _reserveIn.mul(FEE_RATIO).add(amountInWithFee);
        if (denominator <= 0) {
            return 0;
	}
        amountOut = numerator.div(denominator);
    }

    function getAmountInWithFee(uint _amountOut, uint _reserveIn, uint _reserveOut, uint _fee) internal pure returns (uint amountIn) {
        assert(_amountOut > 0);
        if (_reserveIn <= 0 || _reserveOut <= 0) return 0;
        uint numerator = _reserveIn.mul(_amountOut).mul(FEE_RATIO);
        if (_reserveOut <= _amountOut) {
            return 0;
        }
        uint denominator = _reserveOut.sub(_amountOut).mul(FEE_RATIO.sub(_fee));
        if (denominator <= 0) {
            return 0;
	}
        amountIn = numerator.div(denominator).add(1);
    }

    function sortTokens(address _tokenA, address _tokenB) internal pure returns (address token0, address token1) {
        assert(_tokenA != _tokenB);
        (token0, token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
        assert(token0 != address(0));
    }

    function getReserves(IFactory _factory, address _tokenA, address _tokenB) internal view returns (uint reserveA, uint reserveB, address pair) {
        (address token0,) = sortTokens(_tokenA, _tokenB);
        pair = _factory.getPair(_tokenA, _tokenB);
        (uint reserve0, uint reserve1,) = IBabyPair(pair).getReserves();
        (reserveA, reserveB) = _tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    
    function getAmountsOut(IFactory[] memory _factories, uint[] memory _fees, uint _amountIn, address[] memory _path) internal view returns (uint[] memory amounts, uint[] memory impact, address[] memory pairs) {
        assert(_path.length >= 2 && _factories.length == _fees.length && _factories.length + 1 == _path.length);
        amounts = new uint[](_path.length);
        impact = new uint[](_path.length - 1);
        pairs = new address[](_path.length - 1);
        amounts[0] = _amountIn;
        for (uint i; i < _path.length - 1; i++) {
            (uint reserveIn, uint reserveOut, address pair) = getReserves(_factories[i], _path[i], _path[i + 1]);
            pairs[i] = pair;
            amounts[i + 1] = getAmountOutWithFee(amounts[i], reserveIn, reserveOut, _fees[i]);
            if (amounts[i + 1] <= 0) {
                return (new uint[](0), new uint[](0), new address[](0));
            }
            impact[i] = amounts[i + 1].mul(1e18).div(reserveOut.sub(amounts[i + 1]));
        }
    }

    function getAmountsIn(IFactory[] memory _factories, uint[] memory _fees, uint amountOut, address[] memory _path) internal view returns (uint[] memory amounts, uint[] memory impact, address[] memory pairs) {
        assert(_path.length >= 2 && _factories.length == _fees.length && _factories.length + 1 == _path.length);
        amounts = new uint[](_path.length);
        impact = new uint[](_path.length - 1);
        pairs = new address[](_path.length - 1);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = _path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut, address pair) = getReserves(_factories[i - 1], _path[i - 1], _path[i]);
            pairs[i - 1] = pair;
            amounts[i - 1] = getAmountInWithFee(amounts[i], reserveIn, reserveOut, _fees[i - 1]);
            if (amounts[i - 1] <= 0) {
                return (new uint[](0), new uint[](0), new address[](0));
            }
            impact[i - 1] = amounts[i].mul(1e18).div(reserveOut.sub(amounts[i]));
        }
    }

    struct RouteInfo {
        uint[] amounts;
        IFactory[] factories;
        address[] pairs;
        uint[] fees;
        uint[] impact;
        address[] path;
    }

    function calculateAmountOut(address _tokenA, address _tokenB, uint _amountIn) external view returns (RouteInfo[] memory routes) {
        SwapPath[] memory paths = getPath(_tokenA, _tokenB);
        routes = new RouteInfo[](paths.length);
        uint routeIndex = 0;
        for (uint i = 0; i < paths.length; i ++) {
            SwapPath memory path = paths[i];
            (uint[] memory amountsOut, uint[] memory impact, address[] memory pairs) = getAmountsOut(path.factories, path.fees, _amountIn, path.path);
            if (amountsOut.length == 0) {
                continue;
	        }
            routes[routeIndex].amounts = amountsOut;
            routes[routeIndex].impact = impact;
            routes[routeIndex].factories = path.factories;
            routes[routeIndex].fees = path.fees;
            routes[routeIndex].path = path.path;
            routes[routeIndex].pairs = pairs;
	        routeIndex ++;
        }
        if (routeIndex < routes.length) {
            assembly {
                mstore(routes, routeIndex)
            }
        }
    }

    function calculateAmountIn(address _tokenA, address _tokenB, uint _amountOut) external view returns (RouteInfo[] memory routes) {
        SwapPath[] memory paths = getPath(_tokenA, _tokenB);
        routes = new RouteInfo[](paths.length);
        uint routeIndex = 0;
        for (uint i = 0; i < paths.length; i ++) {
            SwapPath memory path = paths[i];
            (uint[] memory amountsIn, uint[] memory impact, address[] memory pairs) = getAmountsIn(path.factories, path.fees, _amountOut, path.path);
            if (amountsIn.length == 0) {
                continue;
	        }
            routes[routeIndex].amounts = amountsIn;
            routes[routeIndex].impact = impact;
            routes[routeIndex].factories = path.factories;
            routes[routeIndex].fees = path.fees;
            routes[routeIndex].path = path.path;
            routes[routeIndex].pairs = pairs;
	        routeIndex ++;
        }
        if (routeIndex < routes.length) {
            assembly {
                mstore(routes, routeIndex)
            }
        }
    }
}