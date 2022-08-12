//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                                                    ████████████████████
//                                                    ████████████████████
//                                                    ████████████████████
//                                                    ████████████████████
//
//
//  █████╗ ███╗   ██╗ ██████╗ ████████╗██╗  ██╗███████╗██████╗ ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗
// ██╔══██╗████╗  ██║██╔═══██╗╚══██╔══╝██║  ██║██╔════╝██╔══██╗██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝
// ███████║██╔██╗ ██║██║   ██║   ██║   ███████║█████╗  ██████╔╝██████╔╝██║     ██║   ██║██║     █████╔╝
// ██╔══██║██║╚██╗██║██║   ██║   ██║   ██╔══██║██╔══╝  ██╔══██╗██╔══██╗██║     ██║   ██║██║     ██╔═██╗
// ██║  ██║██║ ╚████║╚██████╔╝   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗
// ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
//
/**
 * @title Another721
 * @author Anotherblock Technical Team
 * @notice Anotherblock NFT contract
 **/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './ERC721AB.sol';

contract Another721 is ERC721AB {
    // Base Token URI
    string private baseTokenURI;

    /**
     * @notice
     *  Another721 contract constructor
     *
     * @param _anotherblock : Anotherblock contract address
     * @param _baseUri : base token URI
     * @param _name : name of the NFT contract
     * @param _symbol : symbol / ticker of the NFT contract
     **/
    constructor(
        address _anotherblock,
        string memory _baseUri,
        string memory _name,
        string memory _symbol
    ) ERC721AB(_anotherblock, _name, _symbol) {
        // Sets the base token URI
        baseTokenURI = _baseUri;
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Let a whitelisted user mint `_quantity` token(s) of the given `_dropId`
     *
     * @param _to : address to receive the token
     * @param _dropId : drop identifier
     * @param _quantity : amount of tokens to be minted
     * @param _proof : merkle tree proof used to verify whitelisted user
     */
    function mint(
        address _to,
        uint256 _dropId,
        uint256 _quantity,
        bytes32[] memory _proof
    ) external payable {
        _mintAB(_to, _dropId, _quantity, _proof);
    }

    /**
     * @notice
     *  Let a user mint `_quantity` token(s) of the given `_dropId`
     *
     * @param _userWallet : address to receive the token
     * @param _quantity : amount of tokens to be minted
     * @param _tokenId : drop identifier
     */
    function claimTo(
        address _userWallet,
        uint256 _quantity,
        uint256 _tokenId
    ) external payable {
        bytes32[] memory emptyBytes;

        _mintAB(_userWallet, _tokenId, _quantity, emptyBytes);
    }

    /**
     * @notice
     *  Returns the remaining supply for a given `_dropId`
     *
     * @param _tokenId : drop identifier
     * @return unclaimedSupply : the remaining supply to be minted for `_dropId`
     */
    function unclaimedSupply(uint256 _tokenId) public view returns (uint256) {
        IABDropManager.Drop memory drop = IABDropManager(anotherblock).drops(
            _tokenId
        );

        return drop.tokenInfo.supply - drop.sold;
    }

    /**
     * @notice
     *  Returns the mint price for a given `_dropId`
     *
     * @param _tokenId : drop identifier
     * @return price : the mint price for `_dropId`
     */
    function price(uint256 _tokenId) public view returns (uint256) {
        IABDropManager.Drop memory drop = IABDropManager(anotherblock).drops(
            _tokenId
        );
        return drop.tokenInfo.price;
    }

    /**
     * @notice
     *  Returns the reason why `_to` cannot mint `_quantity` token from `_dropId`
     *
     * @param _userWallet : wallet to receive the minted NFT(s)
     * @param _quantity : quantity to be minted
     * @param _tokenId : drop identifier
     * @return reason : the reason why the user cannot mint
     */
    function getClaimIneligibilityReason(
        address _userWallet,
        uint256 _quantity,
        uint256 _tokenId
    ) public view returns (string memory) {
        IABDropManager.Drop memory drop = IABDropManager(anotherblock).drops(
            _tokenId
        );

        // Check if the drop is not sold-out
        if (drop.sold == drop.tokenInfo.supply) return 'DropSoldOut';

        // Check that the whitelisted sale started
        if (block.timestamp < drop.salesInfo.privateSaleTime)
            return 'SaleNotStarted';

        // Check that there are enough tokens available for sale
        if (drop.sold + _quantity > drop.tokenInfo.supply)
            return 'NotEnoughTokensAvailable';

        if (
            drop.merkleRoot != 0x0 &&
            block.timestamp < drop.salesInfo.publicSaleTime
        ) {
            // Check that user did not mint the maximum amount per address for the private sale
            if (
                mintedPerDropPrivateSale[drop.dropId][_userWallet] + _quantity >
                drop.salesInfo.privateSaleMaxMint
            ) return 'MaxMintPerAddress';
        } else {
            // Check that user did not mint the maximum amount per address for the public sale
            if (
                mintedPerDropPublicSale[drop.dropId][_userWallet] + _quantity >
                drop.salesInfo.publicSaleMaxMint
            ) return 'MaxMintPerAddress';
        }
        return '';
    }

    /**
     * @notice
     *  Withdraw mint proceeds to Anotherblock Treasury address
     *
     */
    function withdrawAll() external {
        payable(IABDropManager(anotherblock).treasury()).transfer(
            address(this).balance
        );
    }

    //
    //     ____        __         ____                              ______                 __  _
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____   / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /     / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/     /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/
    //               /____/

    /**
     * @notice
     *  Update the Base URI
     *  Only the contract owner can perform this operation
     *
     * @param _newBaseURI : new base URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Returns the base URI
     *
     * @return baseTokenURI base token URI state
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}