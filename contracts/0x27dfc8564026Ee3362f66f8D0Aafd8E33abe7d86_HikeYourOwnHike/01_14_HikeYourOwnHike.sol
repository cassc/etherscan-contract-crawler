// SPDX-License-Identifier: CC0
// Copyright (c) 2022 unReal Accelerator, LLC (https://unrealaccelerator.io)
pragma solidity ^0.8.9;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//      ██╗░░██╗██╗██╗░░██╗███████╗  ██╗░░░██╗░█████╗░██╗░░░██╗██████╗░  ░█████╗░░██╗░░░░░░░██╗███╗░░██╗      //
//      ██║░░██║██║██║░██╔╝██╔════╝  ╚██╗░██╔╝██╔══██╗██║░░░██║██╔══██╗  ██╔══██╗░██║░░██╗░░██║████╗░██║      //
//      ███████║██║█████═╝░█████╗░░  ░╚████╔╝░██║░░██║██║░░░██║██████╔╝  ██║░░██║░╚██╗████╗██╔╝██╔██╗██║      //
//      ██╔══██║██║██╔═██╗░██╔══╝░░  ░░╚██╔╝░░██║░░██║██║░░░██║██╔══██╗  ██║░░██║░░████╔═████║░██║╚████║      //
//      ██║░░██║██║██║░╚██╗███████╗  ░░░██║░░░╚█████╔╝╚██████╔╝██║░░██║  ╚█████╔╝░░╚██╔╝░╚██╔╝░██║░╚███║      //
//      ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚══════╝  ░░░╚═╝░░░░╚════╝░░╚═════╝░╚═╝░░╚═╝  ░╚════╝░░░░╚═╝░░░╚═╝░░╚═╝░░╚══╝      //
//                                                                                                            //
//                                        ██╗░░██╗██╗██╗░░██╗███████╗                                         //
//                                        ██║░░██║██║██║░██╔╝██╔════╝                                         //
//                                        ███████║██║█████═╝░█████╗░░                                         //
//                                        ██╔══██║██║██╔═██╗░██╔══╝░░                                         //
//                                        ██║░░██║██║██║░╚██╗███████╗                                         //
//                                        ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚══════╝                                         //
//                                                                                                            //
//                                                                                                            //
//  This collection documents a trek across the revered and rugged footpath known as the Appalachian Trail.   //
//                                                                                                            //
//  Our northbound thru-hike began late winter, a time when less embark and fewer will endure. Surviving      //
//  changing seasons and some transitions of our own, we traversed the white blaze for nearly 2,200 miles.    //
//  After spending months living from a tent or the occasional lean-to, mileage felt secondary to the         //
//  intimate experiences that privileged our journey. Such adventures take grit and determination, even more  //
//  they require a keen desire to expand and evolve. Witnessing an ever-changing environment of resilient     //
//  life instills the belief in our own balance of hardiness and flexibility.                                 //
//                                                                                                            //
//  Caleb and Madelyn’s documentation reveals a process of acceptance and admiration for the ever elusive     //
//  now. Through our pieces, we explore the relationship between nature and long-distance hiker.              //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/// @title: HikeYourOwnHike
/// @author: [email protected]

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract HikeYourOwnHike is
    ERC1155,
    ERC1155Burnable,
    ERC1155Supply,
    Ownable,
    IERC2981
{
    using Counters for Counters.Counter;
    Counters.Counter public nextEditionId;

    struct Edition {
        // unique identifer
        uint256 id;
        // amount of tokens in this edition
        uint128 supply;
        // token uri
        string uri;
        // royalty receiver
        address payable royaltyReceiver;
        // percentage for royalties
        uint96 royaltyFraction;
    }

    Edition[] public editions;

    string public name;
    string public symbol;

    address public administrator;

    error NotAuthorized();
    error InvalidAddress();
    error InvalidSupply();
    error NonExistentEdition();

    /// @notice Emitted when a new Edition is created
    event EditionCreated(uint256 id);
    /// @notice Emitted when an Edition is updated
    event EditionUpdated(uint256 id);

    /**
     * @dev Modifier to check for Admin or Owner role
     */
    modifier onlyAuthorized() {
        validateAuthorized();
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address administrator_
    ) ERC1155("") {
        name = name_;
        symbol = symbol_;
        administrator = administrator_;
    }

    /// @notice Called to create a new Edition and mint it to an address
    /// @param to address to receive mints
    /// @param supply qty of tokens for the new edition
    /// @param uri_ uri for the edition metadata
    /// @param royaltyReceiver address to receive royalties
    /// @param royaltyFraction percent of sales paid to receiver
    //  Requirements:
    //  - `to` cannot be address 0
    //  - `supply` must be greater than 0
    //  - `royaltyReceiver` cannot be address 0
    function createEdition(
        address to,
        uint128 supply,
        string calldata uri_,
        address payable royaltyReceiver,
        uint96 royaltyFraction
    ) external onlyAuthorized {
        if (to == address(0)) revert InvalidAddress();
        if (supply <= 0) revert InvalidSupply();
        if (royaltyReceiver == address(0)) revert InvalidAddress();
        uint256 id = nextEditionId.current();
        editions.push(
            Edition(id, supply, uri_, royaltyReceiver, royaltyFraction)
        );
        _mint(to, id, supply, "0x0000");
        nextEditionId.increment();
        emit EditionCreated(id);
    }

    /// @notice Called to set the administrator address.
    /// @param administrator_ Address for administrator
    //  Requirements - administrator_ cannot be 0 address
    function setAdministrator(address administrator_) external onlyOwner {
        if (administrator_ == address(0)) revert InvalidAddress();
        administrator = administrator_;
    }

    /// @notice Sets the royalty for an edition
    /// @param id unique identifier of the edition being updated
    /// @param royaltyReceiver address to receive royalties
    /// @param royaltyFraction percent of sales paid to receiver
    //  Requirements - royaltyReceiver cannot be 0 address
    function setEditionRoyalty(
        uint256 id,
        address payable royaltyReceiver,
        uint96 royaltyFraction
    ) external onlyAuthorized {
        if (royaltyReceiver == address(0)) revert InvalidAddress();
        editions[id].royaltyReceiver = royaltyReceiver;
        editions[id].royaltyFraction = royaltyFraction;
        emit EditionUpdated(id);
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param id - the NFT asset queried for royalty information
    /// @param salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 id, uint256 salePrice)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        uint256 royaltyAmount = (salePrice * editions[id].royaltyFraction) /
            10000;
        return (editions[id].royaltyReceiver, royaltyAmount);
    }

    /// @notice Called to sets the uri for an edition
    /// @param id unique identifier of the edition being updated
    /// @param uri_ uri for the edition metadata
    function setEditionURI(uint256 id, string calldata uri_)
        external
        onlyAuthorized
    {
        editions[id].uri = uri_;
        emit EditionUpdated(id);
    }

    /// @notice Query the contract for the URI to the edition's metadata
    /// @param id unique identifier of the edition being updated
    /// @return `uri` for the token metadata
    function uri(uint256 id)
        public
        view
        virtual
        override(ERC1155)
        returns (string memory)
    {
        return string(editions[id].uri);
    }

    /// @notice Returns true for supported interfaces
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return `true` for implemented interfaces
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        // - IERC165: 0x01ffc9a7
        // - IERC1155: 0xd9b67a26
        // - IERC2981: 0x2a55205a
        return
            ERC1155.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Override of hook called prior to token transfers
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Supply, ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /// @notice Validate authorized addresses
    function validateAuthorized() private view {
        if (_msgSender() != owner() && _msgSender() != administrator)
            revert NotAuthorized();
    }

    /// @notice helper function to get edition array
    function getEditions() external view returns (Edition[] memory) {
        return editions;
    }

    /// @notice helper function to get an edition
    function getEdition(uint256 id) external view returns (Edition memory) {
        return editions[id];
    }

    /// @notice Fallback functions in case someone sends ETH to the contract
    receive() external payable {}

    fallback() external payable {}

    function withdraw() external payable onlyAuthorized {
        (bool success, ) = payable(_msgSender()).call{
            value: address(this).balance
        }("");
        require(success);
    }
}

// Appalachian Trail
//                                                                            .
//                                                                       ::.:---.
//                                                                      .-------:
//                                                                      :--------:
//                                                                      :---:::---.
//                                                 2,194.3 miles        :---:::----:.
//                                                                     .---=#+-------::
//                                                                     :---+%+-------:.
//                                                                  .::--===----:-::.
//    ..:.                                                     ...:::-:=+=------ .
//    :------.                                         ...:::---::--:=+:------::
//    ..  .                                         .:-------:-::::-+=-::---:.
//        ::::.                                    :---------:-=*==--::::--:
//       .:------.                               .:----------::-*-::-::::::
//     . :-------:                                ------------::#-::-----:.
//    :-:--------:                                :------------:==-::::::::
//    :---------:.  .                         ..:----:::-------:-+:::::---:.
//    :---------. .--:                .:------------------------==--::::::--:.
//    :-----::--:-----:                :------------------------*-::::-:::.:..
//    :-----::---------.              .:-----------:::::::-----===-:::-:..
//    .--------------:.             .:---:::::::::::-----::-=+=-:::..
//     --------------.            ::::::::-----------------+=::::. ...
//    .-------------:         .:::-----------------------=+----:.:..
//    :-::::::::::::.       .:---:-----------::----====+=-::---.
//    :::----::--------:::-------::--------------==--------:::--.
//    :-------:------------------::-------------==*--------:::::
//    :-------:------------------:.-------------+--::::::::---:.
//    :-------:--------:::-------:::----::::::::*::::::.:::..::
//    :--:::--::-----------------:-:::::::::::::*:::::. ::::.
//    :--:::---:--------------::::------::--::-+=--::-: .:::::
//    :--------:-------------::-----------:::=+----::-:..:::::
//    :--------::::---------:::---:::---:::-+=-----:::.:   .:
//    :-----::::--:::::::::::----------::---+---------:::  :.
//    :-----::------------::----------::---+---:::---::::  .
//    :-::-:---------------::---------:---+----------::::.
//    ::::::-----::---------::::-:::======---------------:::
//    :--------------------:::-::===-----------:::::::::::-:.
//    :------------------:::----=*:::::::::::::---------:::...
//    :--------::::::::::::::::*:::-----------------------::::
//    :::::::::::------------==+-----------:::-----------::..
//    :-------:-----------=+=--------------:::----------:::.
//    :-------:::------===------------------------------::.
//    :-------------::+=----::::::::::::::::::--------:.
//    :-------::::::::::==::-----------------::::----:
//    ::::::::::------=+==:::-------------------::::.
//    :--------:-----#*------::-------:::--------.
//    :--------::----##-------:::--------------:.
//    :--:::----:-------::::-----::-----------:.
//    :---------::-----------------:::-------.
//    :----------::------------------::---:.
//    .:::::::::::.:::::::::::::::::::..:.
//
// Maine
// New Hampshire
// Vermont
// Massachusetts
// Connecticut
// New York
// New Jersey
// Pennsylvania
// Maryland
// West Virginia
// Virginia
// Tennessee
// North Carolina
// Georgia