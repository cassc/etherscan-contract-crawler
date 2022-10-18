// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Attributes {
    function metadataBackground(uint256 index)
        internal
        pure
        returns (string memory)
    {
        if (index == 0) {
            return "Blue";
        } else if (index == 1) {
            return "Pink";
        } else {
            return "Yellow";
        }
    }

    function metadataBottom(uint256 index)
        internal
        pure
        returns (string memory)
    {
        if (index == 0) {
            return "Dish";
        } else if (index == 1) {
            return "Glass Cup";
        } else if (index == 2) {
            return "With Strawberry And Ice Cream";
        } else if (index == 3) {
            return "Cake";
        } else if (index == 4) {
            return "Ice Cream Cone";
        } else if (index == 5) {
            return "Soda";
        } else if (index == 6) {
            return "Crepe";
        } else {
            return "Rolled Cake";
        }
    }

    function metadataFace(uint256 index) internal pure returns (string memory) {
        if (index == 0) {
            return "Normal";
        } else if (index == 1) {
            return "Glasses";
        } else if (index == 2) {
            return "Mustache";
        } else if (index == 3) {
            return "Beh";
        } else if (index == 4) {
            return "Dress Up";
        } else if (index == 5) {
            return "Shy Smile";
        } else if (index == 6) {
            return "Sloping";
        } else if (index == 7) {
            return "Surprised";
        } else if (index == 8) {
            return "Sad";
        } else if (index == 9) {
            return "Happy";
        } else if (index == 10) {
            return "Full Stomach";
        } else if (index == 11) {
            return "Calm";
        } else if (index == 12) {
            return "Confident";
        } else {
            return "Awakened";
        }
    }

    function metadataPudding(uint256 index)
        internal
        pure
        returns (string memory)
    {
        if (index == 0) {
            return "Egg";
        } else if (index == 1) {
            return "Chocolate";
        } else if (index == 2) {
            return "Green Tea";
        } else if (index == 3) {
            return "Strawberry";
        } else if (index == 4) {
            return "Jelly";
        } else if (index == 5) {
            return "Black Sesame";
        } else {
            return "Orange";
        }
    }

    function metadataTop(uint256 index) internal pure returns (string memory) {
        if (index == 0) {
            return "None";
        } else if (index == 1) {
            return "Cherry";
        } else if (index == 2) {
            return "Cat";
        } else if (index == 3) {
            return "Mint Cream";
        } else if (index == 4) {
            return "Hamster";
        } else if (index == 5) {
            return "Anko";
        } else if (index == 6) {
            return "Bear";
        } else if (index == 7) {
            return "Strawberry And Cookie";
        } else if (index == 8) {
            return "Rabbit";
        } else if (index == 9) {
            return "Mix Berry";
        } else if (index == 10) {
            return "Pig";
        } else if (index == 11) {
            return "Caramel";
        } else if (index == 12) {
            return "Cream Boy";
        } else if (index == 13) {
            return "Pudding";
        } else {
            return "Bird";
        }
    }
}