// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LiORevival is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public nftContract;

    bool public revivalActive = true;
    uint256 public REVIVAL_FEE = 1 ether;
    address public currency = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BUSD contract address
    address public communityWallet = 0xc4F6748d633A1C0Ef74cA9DBFBF2ecF2b9474308;

    mapping(uint256 => uint256) public revivals;
    event Revive(uint256[] tokenIds);

    function reviveLiOs(uint256[] calldata _tokenIds) external {
        require(revivalActive, "Revival not active!");
        require(
            IERC20(currency).balanceOf(address(msg.sender)) >=
                REVIVAL_FEE.mul(_tokenIds.length),
            "Insufficient funds in wallet."
        );
        uint256 _amount = _tokenIds.length.mul(REVIVAL_FEE);
        // Transfer payments
        IERC20(currency).transferFrom(
            address(msg.sender),
            communityWallet,
            _amount
        );

        _revive(_tokenIds);
    }

    function _revive(uint256[] calldata _reviveTokenIds) private {
        bool[] memory _val = new bool[](_reviveTokenIds.length);
        for (uint256 i = 0; i < _reviveTokenIds.length; i++) {
            require(
                _reviveTokenIds[i] >= 1 && _reviveTokenIds[i] <= 11111,
                "One of the token IDs is not part of the collection!"
            );
            require(
                address(msg.sender) ==
                    IERC721Enumerable(nftContract).ownerOf(_reviveTokenIds[i]),
                "Sender not owner of one of the tokens"
            );
        }
        emit Revive(_reviveTokenIds);
    }

    // Function that allows owner to set the NFT contract address that's being used
    function setNFTContract(address _addr) external onlyOwner {
        nftContract = _addr;
    }

    // Set community wallet that will receive 50% of payments
    function setCommunityWallet(address _addr) external onlyOwner {
        communityWallet = _addr;
    }

    // Function to set currency
    function setCurrency(address _addr) external onlyOwner {
        currency = _addr;
    }
}