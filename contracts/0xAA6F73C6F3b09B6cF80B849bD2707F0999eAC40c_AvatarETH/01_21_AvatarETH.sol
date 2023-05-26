import '../NiftyEnumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract AvatarETH is NiftyEnumerable, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        address _royaltyWallet
    ) NiftyEnumerable(uri, name, symbol, tx.origin) {
        _setRoyaltyWallet(_royaltyWallet);
    }

    function mint(
        address to,
        uint256 tokenId,
        string calldata _data
    ) public isMinter returns (uint256) {
        _mint(to, tokenId);
    }
}