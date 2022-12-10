import "../nfts/ERC1155Invoke.sol";

contract ParallelAlphaArtigraphSeries is ERC1155Invoke {
    constructor()
    ERC1155Invoke(
        true,
        "https://nftdata.parallelnft.com/api/parallel-artigraph/ipfs/",
        "ParallelAlphaArtigraphSeries",
        "LLAS"
    )
    {}
}