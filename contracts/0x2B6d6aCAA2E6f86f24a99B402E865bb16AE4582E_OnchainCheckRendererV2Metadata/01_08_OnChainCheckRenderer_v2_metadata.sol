// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Compiler.sol";
import "./Base64.sol";
import "./IMetaDataURI.sol";
import "./OnChainCheckRenderer_v2_interface.sol";
import "./GasLibs.sol";

contract OnchainCheckRendererV2Metadata is IMetaDataURI, Ownable {

  uint256 private immutable MAX_MINT_GAS_PRICE = 1000000; // 1000 gwei mint would show all checks
  IDataChunkCompiler private compiler;
  IOnChainCheckRenderer_v2_Render public animationUrlMetadata;
  IOnChainCheckRenderer_v2_Render public imageMetadata;

  constructor(
    address _compiler,
    address _animationUrlMetadata,
    address _imageMetadata
  ) {
    imageMetadata = IOnChainCheckRenderer_v2_Render(_imageMetadata);
        compiler = IDataChunkCompiler(_compiler);
    animationUrlMetadata = IOnChainCheckRenderer_v2_Render(
      _animationUrlMetadata
    );
  }

  function setAnimationUrlMetadata(address _animationUrlMetadata)
    public
    onlyOwner
  {
    animationUrlMetadata = IOnChainCheckRenderer_v2_Render(
      _animationUrlMetadata
    );
  }

  function setImageMetadata(address _imageMetadata) public onlyOwner {
    imageMetadata = IOnChainCheckRenderer_v2_Render(_imageMetadata);
  }

  function tokenURI(
    uint256 tokenId,
    uint256 seed,
    uint24 gasPrice
  ) public view returns (string memory) {
    string memory tokenIdStr = GasLibs.uint2str(tokenId);
    bool[80] memory isCheckRendered = GasLibs.getIsCheckRendered(
      seed,
      gasPrice
    );
    bool isDark = seed % 2 == 0;

    return
      string.concat(
        compiler.BEGIN_JSON(),
        string.concat(
          compiler.BEGIN_METADATA_VAR("animation_url", false),
          animationUrlMetadata.render(
            tokenId,
            seed,
            gasPrice,
            isDark,
            isCheckRendered
          ),
          compiler.END_METADATA_VAR(false)
        ),
        string.concat(
          compiler.BEGIN_METADATA_VAR("image", false),
          "data:image/svg+xml;base64,",
          Base64.encode(
            bytes(
              imageMetadata.render(
                tokenId,
                seed,
                gasPrice,
                isDark,
                isCheckRendered
              )
            )
          ),
          compiler.END_METADATA_VAR(false)
        ),
        string.concat(
          compiler.BEGIN_METADATA_VAR("attributes", true),
          "%5B%7B%22trait_type%22%3A%22gas%20at%20mint%22%2C%22value%22%3A",
          GasLibs.uint2str(gasPrice / 1000),
          "%7D%2C%7B%22trait_type%22%3A%22dark%22%2C%22value%22%3A%22",
          isDark ? "true" : "false",
          "%22%7D%2C%7B%22trait_type%22%3A%22color%20delta%22%2C%22value%22%3A%22",
          GasLibs.uint2str(GasLibs.getMaxDelta(seed)),
          "%20gwei%22%7D%2C%7B%22trait_type%22%3A%22number%20of%20checkmarks%22%2C%22value%22%3A",
          GasLibs.uint2str(GasLibs.getNumberOfCheckMarks(isCheckRendered)),
          "%7D%5D%2C"
        ),
        string.concat(
          compiler.BEGIN_METADATA_VAR("name", false),
          "Onchain%20Gas%20Check%20%23",
          tokenIdStr,
          "%22" // no trailing comma for last element
        ),
        compiler.END_JSON()
      );
  }
}