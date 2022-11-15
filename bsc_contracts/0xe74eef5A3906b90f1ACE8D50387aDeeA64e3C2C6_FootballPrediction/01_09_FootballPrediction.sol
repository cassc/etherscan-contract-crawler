// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface FootBall {
    function editDeadStatus(uint256[] calldata _tokenId, bool[] calldata _status) external;

    function getDeadStatus(uint256[] calldata _tokenIds) external view returns (bool[] memory);
}

contract FootballPrediction is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    address public nftContract;

    mapping(uint256 => uint256) public predictedOutcome;
    uint256[] public tokenIdsPredicted;
    bool public predictionOpen = true;

    // Allows owner of token IDs that are alive predict an outcome.
    // A dead token ID will result in failure.
    // Acceptable _outcomes values =>
    //      1 => Lose
    //      2 => Win
    //      3 => Tie
    function pickOutcome(uint256[] calldata _tokenIds, uint256[] calldata _outcomes) external {
        require(predictionOpen, "Prediction not yet open.");
        bool[] memory deadStatus = FootBall(nftContract).getDeadStatus(_tokenIds);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(!deadStatus[i], "One of the token IDs is dead!");
            require(_outcomes[i] >= 1 && _outcomes[i] <= 3, "Invalid outcome");
            require(
                IERC721Enumerable(nftContract).ownerOf(_tokenIds[i]) == address(msg.sender),
                "Sender not owner of one of the token IDs"
            );

            predictedOutcome[_tokenIds[i]] = _outcomes[i];
        }
    }

    // Function for owner to set the outcome.
    // This function will kill all NFTs that predicted the wrong outcome
    // function setOutcome(uint256 _outcome) external onlyOwner {
    //     require(_outcome >= 1 && _outcome <= 3, "Invalid outcome");

    //     predictionOpen = false; // Close prediction once outcome is set

    //     uint256[] memory _tokenIds = new uint256[](IERC721Enumerable(nftContract).totalSupply());
    //     bool[] memory _dead = new bool[](IERC721Enumerable(nftContract).totalSupply());

    //     // Add all wrong outcomes to an array
    //     for (uint256 i = 0; i < _tokenIds.length; i++) {
    //         _tokenIds[i] = i + 1;
    //         if (predictedOutcome[i] != _outcome) _dead[i] = true;
    //     }

    //     // Kill all Token IDs in arrary filled with wrong outcomes
    //     FootBall(nftContract).editDeadStatus(_tokenIds, _dead);
    // }

    function setPredictionStatus(bool _val) external onlyOwner {
        predictionOpen = _val;
    }

    // Function that allows owner to set the NFT contract address that's being used
    function setNFTContract(address _addr) external onlyOwner {
        nftContract = _addr;
    }

    function getPredictions(uint256[] calldata _tokenIds) external view returns (uint256[] memory) {
        uint256[] memory predictions = new uint256[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            predictions[i] = predictedOutcome[_tokenIds[i]];
        }
        return predictions;
    }
}