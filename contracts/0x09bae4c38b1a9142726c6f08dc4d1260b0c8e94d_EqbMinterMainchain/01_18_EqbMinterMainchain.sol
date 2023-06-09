// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./EqbMinterBaseUpg.sol";

contract EqbMinterMainchain is EqbMinterBaseUpg {
    uint256 public constant _1_MILLION = 1e24;
    uint256 public multiplier;
    uint256 public deflation;

    uint256 public totalMintedAmount;
    mapping(uint256 => uint256) public mintedAmounts;

    event MultiplierUpdated(uint256 _multiplier);
    event DeflationUpdated(uint256 _deflation);
    event TotalMintedAmountUpdated(uint256 _totalMintedAmount);
    event MintedAmountsUpdated(uint256 _chainId, uint256 _amount);
    event FactorBroadcasted(uint256[] _chainIds, uint256 _factor);

    function initialize(
        address _eqb,
        address _eqbMsgSendEndpoint,
        uint256 _approxDstExecutionGas,
        address _eqbMsgReceiveEndpoint
    ) public initializer {
        __EqbMinterBase_init(
            _eqb,
            _eqbMsgSendEndpoint,
            _approxDstExecutionGas,
            _eqbMsgReceiveEndpoint
        );

        multiplier = DENOMINATOR;
        deflation = DENOMINATOR;
        emit MultiplierUpdated(DENOMINATOR);
        emit DeflationUpdated(DENOMINATOR);
    }

    function setMultiplier(
        uint256 _multiplier,
        uint256[] calldata _chainIds
    ) external payable onlyOwner {
        multiplier = _multiplier;

        emit MultiplierUpdated(_multiplier);

        if (_chainIds.length > 0) {
            broadcastFactor(_chainIds);
        }
    }

    function broadcastFactor(
        uint256[] calldata _chainIds
    ) public payable refundUnusedEth {
        if (_chainIds.length == 0) {
            revert Errors.ArrayEmpty();
        }
        uint256 factor = getFactor();
        for (uint256 i = 0; i < _chainIds.length; i++) {
            _sendMessage(_chainIds[i], abi.encode(factor));
        }
        emit FactorBroadcasted(_chainIds, factor);
    }

    function _executeMessage(
        uint256 _srcChainId,
        address,
        bytes memory _message
    ) internal override {
        uint256 amount = abi.decode(_message, (uint256));
        _updateAmountForChain(_srcChainId, amount);
    }

    function _afterMint() internal override {
        _updateAmountForChain(block.chainid, mintedAmount);
    }

    function _updateAmountForChain(uint256 _chainId, uint256 _amount) internal {
        uint256 curMintedAmount = mintedAmounts[_chainId];
        mintedAmounts[_chainId] = _amount;

        uint256 power = ((totalMintedAmount + _amount - curMintedAmount) /
            _1_MILLION) - (totalMintedAmount / _1_MILLION);
        for (uint256 i = 0; i < power; i++) {
            deflation = (deflation * 95) / 100;
        }

        totalMintedAmount = totalMintedAmount - curMintedAmount + _amount;

        emit DeflationUpdated(deflation);
        emit MintedAmountsUpdated(_chainId, mintedAmounts[_chainId]);
        emit TotalMintedAmountUpdated(totalMintedAmount);
    }

    function getFactor() public view override returns (uint256) {
        return (multiplier * deflation) / DENOMINATOR;
    }
}