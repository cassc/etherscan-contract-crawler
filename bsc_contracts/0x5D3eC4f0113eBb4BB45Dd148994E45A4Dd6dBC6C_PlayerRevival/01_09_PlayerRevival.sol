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

contract PlayerRevival is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public nftContract;

    bool public revivalActive = true;
    uint256 public REVIVAL_LIMIT = 2;
    uint256 public REVIVAL_FEE = 2 ether;
    address public currency = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BUSD contract address
    address public communityWallet = 0xc4F6748d633A1C0Ef74cA9DBFBF2ecF2b9474308;
    address public artistWallet = 0x1de57cB58048dFAeE8D61A5634D13Bac120Ce34a;
    address public devWallet = 0xC51283E6A879744b272BaeCdAe1036799352Dfe9;

    mapping(uint256 => uint256) public revivals;
    event Revive(uint256[] tokenIds);

    function revivePlayers(uint256[] calldata _tokenIds) external {
        require(revivalActive, "Revival not active!");
        // require(_amount == REVIVAL_FEE.mul(_tokenIds.length), "Sent payment is incorrect!");
        require(IERC20(currency).balanceOf(address(msg.sender)) >= REVIVAL_FEE.mul(_tokenIds.length), "Insufficient funds in wallet.");
        uint256 _amount = _tokenIds.length.mul(REVIVAL_FEE);
        // Transfer payments
        IERC20(currency).transferFrom(address(msg.sender), communityWallet, _amount.div(2));
        IERC20(currency).transferFrom(address(msg.sender), artistWallet, _amount.div(4));
        IERC20(currency).transferFrom(address(msg.sender), devWallet, _amount.div(4));

        _revive(_tokenIds);
    }

    function _revive(uint256[] calldata _reviveTokenIds) private {
        bool[] memory _val = new bool[](_reviveTokenIds.length);
        for (uint256 i = 0; i < _reviveTokenIds.length; i++) {
            require(_reviveTokenIds[i] >= 1 && _reviveTokenIds[i] <= 11111, "One of the token IDs is not part of the collection!");
            require(revivals[_reviveTokenIds[i]] < REVIVAL_LIMIT, "One of the token IDs cannot be revived anymore!");
            require(
                address(msg.sender) == IERC721Enumerable(nftContract).ownerOf(_reviveTokenIds[i]),
                "Sender not owner of one of the tokens"
            );
            revivals[_reviveTokenIds[i]]++;
            // _val[i] = true;
        }
        FootBall(nftContract).editDeadStatus(_reviveTokenIds, _val);
        emit Revive(_reviveTokenIds);
    }

    function getRevives(uint256[] calldata _tokenIds) external view returns (uint256[] memory) {
        uint256[] memory _revives = new uint256[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) _revives[i] = revivals[_tokenIds[i]];
        return _revives;
    }

    function setRevives(uint256[] calldata _tokenIds, uint256[] calldata _val) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) revivals[_tokenIds[i]] = _val[i];
    }

    // Function that allows owner to set the NFT contract address that's being used
    function setNFTContract(address _addr) external onlyOwner {
        nftContract = _addr;
    }

    // Set dev wallet that will receive 25% of payments
    function setDevWallet(address _addr) external onlyOwner {
        devWallet = _addr;
    }

    // Set artist wallet that will receive 25% of payments
    function setArtistWallet(address _addr) external onlyOwner {
        artistWallet = _addr;
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