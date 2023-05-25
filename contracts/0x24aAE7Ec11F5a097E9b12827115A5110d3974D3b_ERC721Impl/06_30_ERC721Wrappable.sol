// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "../../Access/AccessMinter.sol";
import "./IERC721Wrappable.sol";

abstract contract ERC721Wrappable is Ownable, IERC721Wrappable {

    function transferCollectionOwnership(address _colAddress, address _newOwner) public override onlyOwner {
        require(_colAddress != address(0) && _colAddress != address(this),
            'ERC721Wrappable: collection address needs to be different than zero and current address!');
        require(_newOwner != address(0) && _newOwner != address(this),
            'ERC721Wrappable: new address needs to be different than zero and current address!');
        AccessMinter(_colAddress).changeMinter(_newOwner);
        emit CollectionOwnershipTransferred(_colAddress, address(this), _newOwner);
    }
}