// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
              ___ ___         __     __ _______ __     __
              |   |   |.-----.|__|.--|  |     __|  |--.|__|.-----.
              |   |   ||  _  ||  ||  _  |__     |     ||  ||  _  |
              \_____/ |_____||__||_____|_______|__|__||__||   __|
                                                          |__|

                            https://voidrunners.io

                          ,                         ,,
                         @@@           @@          ,@@@
                        ]@@@@         ]@@W         @@@@
                        ]@@@@         @@@@         [email protected]@@
                        ]@@@[        ]@@@@L        [email protected]@@
                        ]@@@[        @@@@@@        [email protected]@@
                        ]@@@@       ]@@@@@@P       @@@@
                        ]@@@@       @@@@@@@@       @@@@-
                        ]@@@@       @@@@@@@@       @@@@-
                        ]@@@P      ]@@@@@@@@       [email protected]@@L
                        ]@@@K      [email protected]@@@@@@@K      [email protected]@@P
                        ]@@@K      @@@@@@@@@@      [email protected]@@K
                     ,g [email protected]@@P ,,[email protected]@@@@@@@@@@@@@g,  [email protected]@@K]g,
                  [email protected]@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@w
                 ]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                 ]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@P
                    *[email protected]@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@[email protected]@@@]@@P'
                      - @@@@@@@@P RNNNNNNNNNNP *@@@@@@@@ `
                        @@@@@@"                  *%@@@@@
                      [email protected]@@@@                       "%@@@@g
                    [email protected]@@@@P                         '[email protected]@@@@g
                  [email protected]@@@@@-                             %@@@@@g
                [email protected]@@@@@P                                ]@@@@@@g
              [email protected]@@@@@@P                                  ]@@@@@@@g
            [email protected]@@@@N*"-                                     "*[email protected]@@@@g
          ,@@N*"                                                "*[email protected]@g
          "                                                           '
*/

import "@openzeppelin/contracts/utils/Strings.sol";
import "./Void721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

error ShipNotFound();

/**
  @title VoidShip, a spaceship in the Void Runners Genesis Fleet
  @notice A Void721 NFT with a modular data/rendering contract

  See also: Void721 and DropShop721
*/
contract VoidShip is Void721 {
    using Strings for uint256;

    event DataAddressUpdated(address newAddr);

    // our modular data storage and tokenURI() rendering contract
    // this is an IVoidShipData, but we only require that it conform to IERC721Metadata
    address public dataAddress;

    /// @notice setup our spaceship
    constructor(
        string memory _metadataBaseURI,
        uint256 _cap,
        address _royaltyRecipient,
        address _openseaProxy
    )
        Void721(
            "Void Runners Genesis Fleet",
            "VRGF",
            _metadataBaseURI,
            _cap,
            _royaltyRecipient,
            _openseaProxy
        )
    {}

    /// @notice set the address of our VoidShipData contract
    function setDataAddress(address newAddr) public onlyOwner {
        dataAddress = newAddr;
        emit DataAddressUpdated(newAddr);
    }

    /// @notice standard ERC721 metadata lookup function; delegates to our VoidShipData contract, if set
    function tokenURI(uint256 id) public view override returns (string memory) {
        if (!_exists(id)) {
            revert ShipNotFound();
        }

        if (dataAddress == address(0)) {
            return string(abi.encodePacked(baseURI, id.toString()));
        }

        return IERC721Metadata(dataAddress).tokenURI(id);
    }
}