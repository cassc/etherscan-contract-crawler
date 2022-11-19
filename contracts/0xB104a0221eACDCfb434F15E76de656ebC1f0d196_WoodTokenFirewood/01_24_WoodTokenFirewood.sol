//
//
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                           (                                             //
//  (  (                (       *   )        )               )\ )                                    (     //
//  )\))(   '           )\ )  ` )  /(     ( /(    (         (()/(  (   (      (   (  (               )\ )  //
// ((_)()\ )  (    (   (()/(   ( )(_))(   )\())  ))\  (      /(_)) )\  )(    ))\  )\))(    (    (   (()/(  //
// _(())\_)() )\   )\   ((_)) (_(_()) )\ ((_)\  /((_) )\ )  (_))_|((_)(()\  /((_)((_)()\   )\   )\   ((_)) //
// \ \((_)/ /((_) ((_)  _| |  |_   _|((_)| |(_)(_))  _(_/(  | |_   (_) ((_)(_))  _(()((_) ((_) ((_)  _| |  //
//  \ \/\/ // _ \/ _ \/ _` |    | | / _ \| / / / -_)| ' \)) | __|  | || '_|/ -_) \ V  V // _ \/ _ \/ _` |  //
//   \_/\_/ \___/\___/\__,_|    |_| \___/|_\_\ \___||_||_|  |_|    |_||_|  \___|  \_/\_/ \___/\___/\__,_|  //
//                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract WoodTokenFirewood is
    ERC1155Burnable,
    Ownable,
    DefaultOperatorFilterer
{
    string public name = "WoodTokenFirewood";
    string public symbol = "WTF";
    string public contractUri = "https://wood.garten-staudinger.de/contract";

    address public burnTokenAddress =
        0x76aF07CdCa572127aa8160f1466DE4776d157181;

    using Counters for Counters.Counter;
    Counters.Counter private _idTracker;

    constructor() ERC1155("https://wood.garten-staudinger.de/{id}") {
        _idTracker.increment();
    }

    function setBurnTokenAddress(address _address) public onlyOwner {
        burnTokenAddress = _address;
    }

    function setUri(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setContractURI(string memory newuri) public onlyOwner {
        contractUri = newuri;
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function nextTokenId() public view returns (uint256) {
        return _idTracker.current();
    }

    function airdrop(
        address[] memory to,
        uint256[] memory id,
        uint256[] memory amount
    ) public onlyOwner {
        require(
            to.length == id.length && to.length == amount.length,
            "Length mismatch"
        );
        for (uint256 i = 0; i < to.length; i++)
            _mint(to[i], id[i], amount[i], "");
    }

    function mint(uint256 burnTokenId) public {
        ERC1155PresetMinterPauser burnTokenToken = ERC1155PresetMinterPauser(
            burnTokenAddress
        );

        require(
            burnTokenToken.balanceOf(msg.sender, burnTokenId) >= 1,
            "No tokens to burn"
        );
        require(
            burnTokenToken.isApprovedForAll(msg.sender, address(this)),
            "Not approved"
        );
        burnTokenToken.burn(msg.sender, burnTokenId, 1);

        //Mint 4 Wood Token Firewood
        _mint(msg.sender, _idTracker.current(), 1, "");
        _idTracker.increment();
        _mint(msg.sender, _idTracker.current(), 1, "");
        _idTracker.increment();
        _mint(msg.sender, _idTracker.current(), 1, "");
        _idTracker.increment();
        _mint(msg.sender, _idTracker.current(), 1, "");
        _idTracker.increment();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}