pragma solidity =0.5.16;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./interfaces/IBaseV1Pair.sol";
import "./MonolithVaultToken.sol";
import "./interfaces/IMonolithVaultTokenFactory.sol";

contract MonolithVaultTokenFactory is Ownable, IMonolithVaultTokenFactory {
    address public optiSwap;
    address public router;
    address public lpDepositor;
    address public pairFactory;
    address public rewardTokenHelper;
    address public reinvestFeeTo;

    mapping(address => address) public getVaultToken;
    address[] public allVaultTokens;

    constructor(
        address _optiSwap,
        address _router,
        address _lpDepositor,
        address _pairFactory,
        address _rewardTokenHelper,
        address _reinvestFeeTo
    ) public {
        optiSwap = _optiSwap;
        router = _router;
        lpDepositor = _lpDepositor;
        pairFactory = _pairFactory;
        rewardTokenHelper = _rewardTokenHelper;
        reinvestFeeTo = _reinvestFeeTo;
    }

    function allVaultTokensLength() external view returns (uint256) {
        return allVaultTokens.length;
    }

    function createVaultToken(address _underlying)
        external
        returns (address vaultToken)
    {
        require(
            getVaultToken[_underlying] == address(0),
            "VaultTokenFactory: POOL_EXISTS"
        );
        require(!IBaseV1Pair(_underlying).stable(), "VaultTokenFactory: IS_STABLE");
        bytes memory bytecode = type(MonolithVaultToken).creationCode;
        assembly {
            vaultToken := create2(0, add(bytecode, 32), mload(bytecode), _underlying)
        }
        MonolithVaultToken(vaultToken)._initialize(
            _underlying,
            optiSwap,
            router,
            lpDepositor,
            pairFactory,
            rewardTokenHelper,
            reinvestFeeTo
        );
        getVaultToken[_underlying] = vaultToken;
        allVaultTokens.push(vaultToken);
        emit VaultTokenCreated(_underlying, vaultToken, allVaultTokens.length);
    }
}