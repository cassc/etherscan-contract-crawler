pragma solidity ^0.7.3;
interface MoonCatRescue {
    function getCatDetails(bytes5 catId)
        external
        view
        returns (
            bytes5 id,
            address owner,
            bytes32 name,
            address onlyOfferTo,
            uint256 offerPrice,
            address requester,
            uint256 requestPrice
        );

    function rescueOrder(uint256 _rescueOrder)
        external
        view
        returns (bytes5 catId);

    function acceptAdoptionOffer(bytes5 catId) external payable;

    function acceptAdoptionRequest(bytes5 catId) external;

    function adoptionRequests(bytes5 _catId)
        external
        view
        returns (
            bool exists,
            bytes5 catId,
            address requester,
            uint256 price
        );

    function adoptionOffers(bytes5 _catId)
        external
        view
        returns (
            bool exists,
            bytes5 catId,
            address seller,
            uint256 price,
            address offerOnlyTo
        );

    function giveCat(bytes5 catId, address to) external;

    function catOwners(bytes5) external view returns (address);

    function makeAdoptionOfferToAddress(bytes5 catId, uint256 price, address to) external;

    function makeAdoptionOffer(bytes5 catId, uint256 price) external;

    function withdraw() external;
}