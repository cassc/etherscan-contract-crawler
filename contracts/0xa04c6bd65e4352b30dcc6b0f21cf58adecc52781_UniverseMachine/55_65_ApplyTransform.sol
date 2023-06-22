// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./VertexData.sol";
import "./Matrix.sol";

library ApplyTransform {
    function applyTransform(
        VertexData[] memory vertices,
        Matrix memory transform
    ) external pure returns (VertexData[] memory) {
        VertexData[] memory results = new VertexData[](vertices.length);
        for (uint32 i = 0; i < vertices.length; i++) {
            VertexData memory vertexData = vertices[i];
            VertexData memory transformedVertex = vertexData;

            if (
                transformedVertex.command != Command.Stop &&
                transformedVertex.command != Command.EndPoly
            ) {
                Vector2 memory position = transformedVertex.position;

                (int64 x, int64 y) = MatrixMethods.transform(
                    transform,
                    position.x,
                    position.y
                );
                position.x = x;
                position.y = y;

                transformedVertex.position = position;
            }

            results[i] = transformedVertex;
        }
        return results;
    }
}