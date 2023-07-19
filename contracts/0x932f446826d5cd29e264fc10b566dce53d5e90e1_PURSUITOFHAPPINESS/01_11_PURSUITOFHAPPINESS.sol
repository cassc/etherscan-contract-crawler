// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.12;

/// @title: PURSUIT OF HAPPINESS (VAN) Renderer
/// @author: white lights

import './ITokenURISupplier.sol';
import './IDataCompiler.sol';
import './IStringChunk.sol';
import './IBytesChunk.sol';
import './IFileStore.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//                                        ╓                                          //
//                             └⌐        ▓▌  ,▓¬        ,▄▓                          //
//                ²▄,        ╫⌐ ▓ ▌    ╒J▓⌐ ▓▓¬    ╓▄▄▓▓▓▓▀         ,▄▄▓▀            //
//                 ▐▓▌ ▓     ▓▄▓▓ ▓⌐   j▓▓ ▓▓▌ ▄▓▓▓▓▓▓▓▀▐▄▌▓▓▓▓▓▓▓▓▓▓▓▓              //
//                 ▐▓▓ ▓    ▓▓▓▓▓ ▓▓   ▓▓▓ ▓▓▌▐▓▀▀▀▓▓▓ ▐▓▓▓▓▓█▀▀╙¬¬└▀▓               //
//                 ▓▓▓▓▓   ▓▓▓▓▓ ▐▓▓  ▐▓▓▌ ▓▓▌▐▌   j▓▓ ▓▓▓▓▀                         //
//                ▐▓▓▓▓▓   ▓▓▓▓▓ ▓▓▓  ▐▓▓▓ ▓▓▌     ]▓▓ ▓▓▓▌    ▄▄                    //
//                 ▓▓▓▓▓  ▄▓▓▓▓▓ ╫▓▓▓▓▓▓▓▌ ▓▓▌     ▓▓▓ ▐▓▓µ ,▓▓▓                     //
//                  ▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▀▓▓▓▌ ▓▓▌    ▄▓▓▓ ▐▓▓▓▓█▀▀Γ                     //
//                  ▀▓▓▓▓▓▓▓▓▓▓  ▓▓▓▄ ▐▓▓▌ ▓▓▌   ▀▓▓▓▌ ╫▓▓▀                          //
//                   ▓▓▓▓▓▓▓█▓▓  ▀▓▓b ▐▓▓▓ ▓▓▌    ▓▓▓  ▓▓▓       ╓▌                  //
//                   ▐▓▓▌╙¬¬ j▓▌  ▓▓   ▓▓▓ ▓▓▄   ▐▓▓  ▐▓▓▓   ▓▓▓▓▓                   //
//                  ,▓▓█`   ,▓█` ▄▓▀  ▄▓▓▀▄▓▀   ╓▓█¬ ▄▓▓▓▀ ,▓▓▓▓▓▀                   //
//                 ▓▓▓     ▓▓  ▄▓╙  ▄▓▓`▄▓▀   ╒▓▓  ╓▓▓▓▀  ▓▓▓▓▓▀                     //
//                 ▀▓▓▄    ▀▓▄ ╙▓▄  ╙█▓▄╙▓▓µ   ▀▓▄  ▀▓▓▌⌐ ▀▓▓▓▓▌                     //
//                  ▐▓█▌    ▀▓  ▐▓    ▓▓ ╫▓▀   ▐▓¬  ▐▓▓▓▓▓▓▓▓▓▓▓                     //
//                   ▓ ▀     ▀  ▐     ▀▌ ▓▌    ▓¬   ▀▀¬ ▐▓▓▓█▀▀                      //
//                   ▓                ▐▓ ▓⌐   ▐▓         ▓\                          //
//                   ▐                 ▓ ▓    ▐¬        '▌                           //
//                                   ▓∩.         ]▄                                  //
//       ▓µ             ╓▌         ▄▓▓▓ ▓       ▄▐▓              ╓▄Æ            µ    //
//       ▓▓▓           ▓▓       ,▄▓▓▓▓▓ ▓▓     ▄▓▓▌  ,▄▄▄▄▄▄▄▓▓▓▓▓▓         ,▄▓▓     //
//     ▄▓▓▓▓▄          ▓▓    ▄▓▓▓▓▓▓▓▓  ▓▓▌    ▓▓▓ ]▓▓▓███▓▓▓▓▓█▓▓▓ ▄▓▓▓▓▓▓▓▓▓▓      //
//     █▀▓▓▓           ▓▓µ  ▓▓▓▓▀▀╙¬   ▐▓▓▓    ▓▓▓ ▓▓█    ▐▓▓▓  ▓▓ ▓▓▓▓▓█▀▀▀▀`       //
//      ╓▓▓▓           ▓▓▌ ▓▓▓▀     ▄▓⌐j▓▓▓▄▄╓▄▓▓▌ ▓      ▓▓▓b  ` ▐▓▓▓▓,             //
//     ▄▓▓▓▓          ]▓▓▌ ▓▓▓   ▓▓▓▓▓µ ▓▓▓▓▓▓▓▓▓▌       .▓▓▓    , ▀▓▓▓▓▓▓▄,         //
//    ╚`  ▓▓▌       ╫▄▐▓▓ ╫▓▓▓▌     ▓▓▌ ▓▓▓█▀╙▀▓▓▓       j▓▓▓    ▐▓   ▀▀▓▓▓▓▓▄       //
//       j▓▓▌       ▓▌.▓▓ ▐▓▓▓▓▓   ▐▓▓▓ ▐▓▓    ╫▓▓        ▓▓▌    ▐▓▓     ▓▓▓▓▓       //
//        ▓▓▓       ▓▓ ▓▓ ▐▓▓▓▓▓µ  └▓▓▓ ▐▓▓    ▐▓▓µ       ▓▓▓    ▐▓▓     ▓▓▓▓▓       //
//       ▓▓▓╙      ▄▓,▓▓▀,▓▓▓▓▓█   ▓▓▓▀,▓▓▀   ,▓▓█       ▄▓▓"   ,▓▓▀    ╓▓▓▓▓▀       //
//     ▄▓▓▀      ╓▓▀▄▓▀,▓▓▓▓▓█¬  ▄▓▓▀.▓▓▀    ▓▓█¬      ▄▓▓▀    ▓▓▀    ,▓▓▓▓▀         //
//     ╙▀▓▓▄     ╙╙▀▓▀█▌▀▀▓▓▓▓▄ç ▀▀▓▓▄▀▀▓▄  ¬▀▀▓▄µ     ╙▀▓▓▄  ¬▀▀▓▄   ╙▀█▓▓▓▄        //
//       ▐▓▓▄     ▄▓▓b▐▓▌ ▐▓▓▓▓▓▓▓▓▓▓▓▌ ▓▓▌    ▓▓▓       j▓▓∩   ,▓▓▓▓     ▓▓▓▌       //
//       └▓▓▓▓▓▓▓▓▓█▀ ▐▓▌   █▓▓▓▓▓▓▓▓▓▌ ▓▓▓    ▓▓▓        ▓▓⌐    └▀▓▓▓▓▓▓▓▓▓▓        //
//        ▓▓▓▓█▀▀¬    j▓▌      ¬    ▓▓▓ ▓▓▓    ▀▓▓        ▓▓        ╙▓▓▓▓▓▓¬         //
//        ▓▓▀          ▓▌           ▓▓▀ ╫▓▓     ▓▌       j▓▌          ▓▓▓█▀          //
//       .▓            ▓            ▓   ╫▓      ▓▌       ▓▀           ╫▓             //
//       Å             ▀            ▓   ▓       ▓       ▓▀            ▓¬             //
//                                              ▌      ▐▀                            //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////

contract PURSUITOFHAPPINESS is ITokenURISupplier, Ownable {
  string private description =
    "the tour was over, we'd survived.";
  string private script =
    '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';
  IDataCompiler private compiler =
    IDataCompiler(0xc458129ECA3a3857E50E426107C631f0e99F211c);
  IFileStore fileStore =
    IFileStore(0x9746fD0A77829E12F8A9DBe70D7a322412325B91);

  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
    return interfaceId == type(ITokenURISupplier).interfaceId;
  }

  function setDescription(string memory des) public onlyOwner {
    description = des;
  }

  function setScript(string memory scr) public onlyOwner {
    script = scr;
  }

  function tokenURI(uint256 id) external view returns (string memory) {

    /**
     *
     * @dev We break up calls to string.concat() in order to avoid stack too
     *      deep errors and avoid inflating the contract size.
     */
    string memory theAttributes = "";

    {
      theAttributes = string.concat(
        compiler.BEGIN_METADATA_VAR("attributes", true),
        '['
      );
    }

    theAttributes = string.concat(
      theAttributes,
      '{"trait_type":"',
        compiler.encodeURI("Series"),
      '","value":"',
        compiler.encodeURI("JEAN CLAUDE DAMN VAN"),
      '"},'
    );

    theAttributes = string.concat(
      theAttributes,
      '{"trait_type":"',
        compiler.encodeURI("Artist"),
      '","value":"',
        compiler.encodeURI("White Lights"),
      '"},' // @dev: no "," for the last attribute in array
    );

    theAttributes = string.concat(
      theAttributes,
      '{"trait_type":"',
        compiler.encodeURI("Date"),
      '","value":"',
        compiler.encodeURI("January 2023"),
      '"}'
    );


    {
      theAttributes = string.concat(
        theAttributes,
        ']',
        compiler.END_METADATA_VAR(true, false)
      );
    }

    string memory theJSON = "";

    {
      theJSON = string.concat(
        compiler.BEGIN_JSON(),
        string.concat(
          compiler.BEGIN_METADATA_VAR("name", false),
          "%F0%9D%96%95%F0%9D%96%9A%F0%9D%96%97%F0%9D%96%98%F0%9D%96%9A%F0%9D%96%8E%F0%9D%96%99%20%F0%9D%96%94%F0%9D%96%8B%20%F0%9D%96%8D%F0%9D%96%86%F0%9D%96%95%F0%9D%96%95%F0%9D%96%8E%F0%9D%96%93%F0%9D%96%8A%F0%9D%96%98%F0%9D%96%98%20(van)",
          compiler.END_METADATA_VAR(false, false)
        )
      );
    }

    {
      theJSON = string.concat(
        theJSON,
        string.concat(
          compiler.BEGIN_METADATA_VAR("artist", false),
          "White%20Lights",
          compiler.END_METADATA_VAR(false, false)
        )
      );
    }

    {
      theJSON = string.concat(
        theJSON,
        string.concat(
          compiler.BEGIN_METADATA_VAR("description", false),
          compiler.encodeURI(description),
          compiler.END_METADATA_VAR(false, false)
        )
      );
    }

    {
      theJSON = string.concat(
        theJSON,
        string.concat(
          compiler.BEGIN_METADATA_VAR("image", false),
          compiler.encodeURI("https://arweave.net/UNHfYtIVxFjLwenG4iepaCOivii5zumeZbzCEaIKfjA"),
          compiler.END_METADATA_VAR(false, false)
        )
      );
    }

    {
      theJSON = string.concat(
        theJSON,
        theAttributes
      );
    }

    {
      theJSON = string.concat(
        theJSON,
        string.concat(
          string.concat(
            compiler.BEGIN_METADATA_VAR("animation_url", false),
            compiler.HTML_HEAD_START(),
            // @dev: text/javascript+gzip flags to the compiler that we want this unzipped in-place
            string.concat(
              compiler.encodeURI(compiler.encodeURI('<script type="text/javascript+gzip" src="data:text/javascript;base64,')),
              fileStore.getFile("p5-v1.5.0.min.js.gz").read(),
              compiler.encodeURI(compiler.encodeURI('"></script>'))
            ),
            string.concat(
              compiler.encodeURI(compiler.encodeURI('<script type="text/javascript+gzip" src="data:text/javascript;base64,')),
              script,
              compiler.encodeURI(compiler.encodeURI('"></script>'))
            ),
            string.concat(
              compiler.encodeURI(compiler.encodeURI('<script src="data:text/javascript;base64,')),
              fileStore.getFile("gunzipScripts-0.0.1.js").read(),
              compiler.encodeURI(compiler.encodeURI('"></script>'))
            ),
            compiler.HTML_HEAD_END()
          ),
          string.concat(
            compiler.BEGIN_SCRIPT(),
            compiler.SCRIPT_VAR("tokenId",  compiler.uint2str(id), true),
            compiler.END_SCRIPT()
          ),
          string.concat(
            compiler.HTML_FOOT(),
            compiler.END_METADATA_VAR(false, true)
          )
        )
      );
    }

    {
      theJSON = string.concat(
        theJSON,
        compiler.END_JSON()
      );
    }

    return theJSON;
  }
}