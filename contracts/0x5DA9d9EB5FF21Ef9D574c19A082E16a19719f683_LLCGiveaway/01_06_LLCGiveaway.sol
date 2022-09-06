//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/ILLC.sol";
import "./interfaces/ILLCTier.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LLCGiveaway is Ownable {
    using Strings for uint256;

    address public LLC;
    address public LLC_TIER;

    // The initial token ID
    uint256 public constant startFrom = 1;

    // Used for random index assignment
    mapping(uint256 => uint256) public tokenMatrix;

    constructor(address _llc, address _llcTier) {
        LLC = _llc;
        LLC_TIER = _llcTier;
    }

    function setLLCNFT(address _llc) external onlyOwner {
        LLC = _llc;
    }

    function setLLCTier(address _llcTier) external onlyOwner {
        LLC_TIER = _llcTier;
    }

    function setTokenMatrix(
        uint256[] calldata _tokenIndexes,
        uint256[] calldata _values
    ) external onlyOwner {
        require(_tokenIndexes.length > 0, "Empty TokenId Array");
        require(_tokenIndexes.length == _values.length, "Invalid Input");

        for (uint256 i = 0; i < _tokenIndexes.length; i++) {
            tokenMatrix[_tokenIndexes[i]] = _values[i];
        }
    }

    function mint(address _who) external onlyOwner {
        uint256 maxIndex = getLLC().totalSupply() - getLLC().tokenCount();
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.coinbase,
                    block.difficulty,
                    block.gaslimit,
                    block.timestamp
                )
            )
        ) % maxIndex;

        uint256 value = 0;

        if (tokenMatrix[random] == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = random;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = tokenMatrix[random];
        }

        // If the last available tokenID is still unused...
        if (tokenMatrix[maxIndex - 1] == 0) {
            // ...store that ID in the current matrix position.
            tokenMatrix[random] = maxIndex - 1;
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            tokenMatrix[random] = tokenMatrix[maxIndex - 1];
        }

        uint256 tokenId = value + startFrom;
        require(
            getLLCTier().LLCRarities(tokenId) ==
                getLLCTier().LEGENDARY_RARITY(),
            string(abi.encodePacked("Not Legendary tokenId: ", tokenId.toString()))
        );

        getLLC().mint(_who, 1);
    }

    function getLLC() public view returns (ILLC) {
        return ILLC(LLC);
    }

    function getLLCTier() public view returns (ILLCTier) {
        return ILLCTier(LLC_TIER);
    }
}