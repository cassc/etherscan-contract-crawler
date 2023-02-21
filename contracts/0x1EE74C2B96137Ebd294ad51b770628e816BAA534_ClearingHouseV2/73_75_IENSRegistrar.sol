import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IENSRegistrar is IERC721 {
    function reclaim(uint256 id, address owner) external;

    function ens() external returns (address ens);

    function baseNode() external view returns (bytes32 base);
}