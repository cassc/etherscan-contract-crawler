// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../interfaces/IRegistryConsumer.sol";
import "../interfaces/IRandomNumberProvider.sol";
import "../token/LockableRevealERC721EnumerableToken.sol";
import "../extras/recovery/BlackHolePrevention.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenFactoryV1 is Ownable, BlackHolePrevention {

    function deploy(
        TokenConstructorConfig memory tokenConfig,
        address _actualOwner
    ) external returns (address) {
        // Launch new token contract
        LockableRevealERC721EnumerableToken token = new LockableRevealERC721EnumerableToken();
        token.setup(tokenConfig);

        // transfer ownership of the new contract to owner
        token.transferOwnership(_actualOwner);
        return address(token);
    }
}