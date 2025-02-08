const std = @import("std");

const c = @import("c");

// Aliases to hint for what the actual contents are
pub const Pointf = Vector3f;

pub const Quaternionf = extern struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub const identity: Quaternionf = .{ .x = 0, .y = 0, .z = 0, .w = 1 };

    pub fn from(xr: c.XrQuaternionf) Quaternionf {
        return @bitCast(xr);
    }

    pub fn to(self: Quaternionf) c.XrQuaternionf {
        return @bitCast(self);
    }

    pub fn lookTo(forward: Vector3f, up: Vector3f) Quaternionf {
        const normalized_forward = forward.normalize().invert();
        const normalized_up = up.normalize();

        const t = normalized_up.cross(normalized_forward).normalize();

        const forward_t_cross = normalized_forward.cross(t);

        const mat: Matrix4x4f = .{
            .m = .{
                t.x,                  t.y,                  t.z,                  0,
                forward_t_cross.x,    forward_t_cross.y,    forward_t_cross.z,    0,
                normalized_forward.x, normalized_forward.y, normalized_forward.z, 0,
                0,                    0,                    0,                    1,
            },
        };
        return mat.getRotation();
    }

    pub fn rotate(self: Quaternionf, vector: Vector3f) Vector3f {
        var ret: Vector3f = undefined;
        c.XrQuaternionf_RotateVector3f(@ptrCast(&ret), @ptrCast(&self), @ptrCast(&vector));
        return ret;
    }
};

pub const Vector2f = extern struct {
    x: f32,
    y: f32,

    pub const zero: Vector2f = .{ .x = 0, .y = 0 };
    pub const one: Vector2f = .{ .x = 1, .y = 1 };

    pub fn from(xr: c.XrVector2f) Vector2f {
        return @bitCast(xr);
    }
};

pub const SimdVector3f = @Vector(3, f32);
pub fn lengthSimdV3f(self: SimdVector3f) f32 {
    return @sqrt(@reduce(.Add, self * self));
}
pub fn lengthSquaredSimdV3f(self: SimdVector3f) f32 {
    return @reduce(.Add, self * self);
}
pub fn dotSimdV3f(self: SimdVector3f, other: SimdVector3f) f32 {
    return @reduce(.Add, self * other);
}
pub fn normalizeSimdV3f(self: SimdVector3f) SimdVector3f {
    const lengthRcp: SimdVector3f = @splat(1.0 / @sqrt(@reduce(.Add, self * self)));

    return self * lengthRcp;
}
pub fn mulSimdV3f(self: SimdVector3f, other: SimdVector3f) SimdVector3f {
    return self * other;
}
pub fn allGreaterThanV3f(self: SimdVector3f, other: SimdVector3f) SimdVector3f {
    return @reduce(.Add, self > other);
}
pub fn allLessThanV3f(self: SimdVector3f, other: SimdVector3f) SimdVector3f {
    return @reduce(.Add, self < other);
}
pub fn invertSimdV3f(self: SimdVector3f) SimdVector3f {
    return -self;
}

pub const Vector3f = extern struct {
    x: f32,
    y: f32,
    z: f32,

    pub const zero: Vector3f = .{ .x = 0, .y = 0, .z = 0 };
    pub const one: Vector3f = .{ .x = 1, .y = 1, .z = 1 };
    pub const natural_up: Vector3f = .{ .x = 0, .y = 1, .z = 0 };
    pub const natural_forward: Vector3f = .{ .x = 0, .y = 0, .z = -1 };
    pub const natural_backward: Vector3f = .{ .x = 0, .y = 0, .z = 1 };

    pub fn from(xr: c.XrVector3f) Vector3f {
        return @bitCast(xr);
    }

    pub fn to(self: Vector3f) c.XrVector3f {
        return @bitCast(self);
    }

    pub fn toSimd(self: Vector3f) SimdVector3f {
        return @bitCast(self);
    }

    pub fn sub(self: Vector3f, other: Vector3f) Vector3f {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
        };
    }

    pub fn length(self: Vector3f) f32 {
        return @bitCast(lengthSimdV3f(@bitCast(self)));
    }

    pub fn lengthSquared(self: Vector3f) f32 {
        return @bitCast(lengthSquaredSimdV3f(@bitCast(self)));
    }

    pub fn distance(self: Vector3f, other: Vector3f) f32 {
        const self_simd: SimdVector3f = @bitCast(self);
        const other_simd: SimdVector3f = @bitCast(other);
        return lengthSimdV3f(@abs(self_simd - other_simd));
    }

    pub fn normalize(self: Vector3f) Vector3f {
        return @bitCast(normalizeSimdV3f(@bitCast(self)));
    }

    pub fn cross(self: Vector3f, other: Vector3f) Vector3f {
        return .{
            .x = self.y * other.z - self.z * other.y,
            .y = self.z * other.x - self.x * other.z,
            .z = self.x * other.y - self.y * other.x,
        };
    }

    pub fn mul(self: Vector3f, other: Vector3f) Vector3f {
        return .{
            .x = self.x * other.x,
            .y = self.y * other.y,
            .z = self.z * other.z,
        };
    }

    pub fn add(self: Vector3f, other: Vector3f) Vector3f {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
        };
    }

    pub fn div(self: Vector3f, other: Vector3f) Vector3f {
        return .{
            .x = self.x / other.x,
            .y = self.y / other.y,
            .z = self.z / other.z,
        };
    }

    pub fn dot(self: Vector3f, other: Vector3f) f32 {
        return dotSimdV3f(@bitCast(self), @bitCast(other));
    }

    pub fn splat(val: f32) Vector3f {
        return .{ .x = val, .y = val, .z = val };
    }

    pub fn allGreaterThan(self: Vector3f, other: Vector3f) Vector3f {
        return @bitCast(allGreaterThanV3f(@bitCast(self), @bitCast(other)));
    }

    pub fn allLessThan(self: Vector3f, other: Vector3f) Vector3f {
        return @bitCast(allLessThanV3f(@bitCast(self), @bitCast(other)));
    }

    pub fn invert(self: Vector3f) Vector3f {
        return @bitCast(invertSimdV3f(@bitCast(self)));
    }
};

pub const Vector4f = extern struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub const zero: Vector4f = .{ .x = 0, .y = 0, .z = 0, .w = 0 };
    pub const one: Vector4f = .{ .x = 1, .y = 1, .z = 1, .w = 1 };

    pub fn from(xr: c.XrVector4f) Vector4f {
        return @bitCast(xr);
    }
};

pub const Spheref = extern struct {
    position: Pointf,
    radius: f32,

    pub fn contains(self: Spheref, point: Pointf) bool {
        return point.distance(self.position) < self.radius;
    }

    pub fn closestPoint(self: Spheref, point: Pointf) Pointf {
        return point.sub(self.position).normalize().mul(.splat(self.radius)).add(self.position);
    }

    pub fn intersectsSphere(self: Spheref, other: Spheref) bool {
        const distance_squared = self.position.sub(other.position).lengthSquared();

        const radius_sum = self.radius + other.radius;
        const radii_squared = radius_sum * radius_sum;

        return distance_squared <= radii_squared;
    }

    pub fn intersectsAabb(self: Spheref, aabb: AABBf) bool {
        const closest_point = aabb.closestPoint(self.position);

        const distance_squared = self.position.sub(closest_point).lengthSquared();
        const radius_squared = self.radius * self.radius;

        return distance_squared <= radius_squared;
    }

    pub fn intersectsPlane(self: Spheref, plane: Planef) bool {
        const closest_point = plane.closestPoint(self.position);

        const distance_squared = self.position.sub(closest_point).lengthSquared();
        const radius_squared = self.radius * self.radius;

        return distance_squared <= radius_squared;
    }
};

pub const AABBf = extern struct {
    min: Vector3f,
    max: Vector3f,

    /// Creates a fixed AABBf struct, making sure min is always less than max
    pub fn from(min: Vector3f, max: Vector3f) AABBf {
        var aabb: AABBf = .{ .min = min, .max = max };

        if (aabb.min.x > aabb.max.x) std.mem.swap(f32, &aabb.min.x, &aabb.max.x);
        if (aabb.min.y > aabb.max.y) std.mem.swap(f32, &aabb.min.y, &aabb.max.y);
        if (aabb.min.z > aabb.max.z) std.mem.swap(f32, &aabb.min.z, &aabb.max.z);

        return aabb;
    }

    pub fn center(self: AABBf) Vector3f {
        return @bitCast((self.min.toSimd() + self.max.toSimd()) * @as(SimdVector3f, @splat(0.5)));
    }

    pub fn contains(self: AABBf, point: Pointf) bool {
        return point.allGreaterThan(self.min) and point.allLessThan(self.max);
    }

    pub fn closestPoint(self: AABBf, point: Pointf) Pointf {
        return @bitCast(std.math.clamp(point.toSimd(), self.min.toSimd(), self.max.toSimd()));
    }

    pub fn intersectsSphere(self: AABBf, sphere: Spheref) bool {
        return sphere.intersectsAabb(self);
    }

    pub fn intersectsAabb(self: AABBf, other: AABBf) bool {
        return @reduce(.And, self.min.toSimd() <= other.max.toSimd()) and @reduce(.And, self.max.toSimd() >= other.min.toSimd());
    }

    pub fn intersectsPlane(self: AABBf, plane: Planef) bool {
        const box_center = self.center();
        const extents: SimdVector3f = self.max.toSimd() - box_center;

        const r = @reduce(.Add, extents * @abs(plane.normal.toSimd()));
        const distance_from_center_to_plane = plane.normal.dot(box_center) - plane.distance;

        return @abs(distance_from_center_to_plane) <= r;
    }

    pub fn size(self: AABBf) Vector3f {
        return @bitCast(self.max.toSimd() - self.min.toSimd());
    }
};

pub const Planef = extern struct {
    normal: Vector3f,
    distance: f32,

    pub fn from(normal: Vector3f, distance: f32) Planef {
        return .{ .normal = normal.normalize(), .distance = distance };
    }

    pub fn fromPoints(p1: Pointf, p2: Pointf, p3: Pointf) Planef {
        const normal = p2.sub(p1).cross(p3.sub(p1)).normalize();

        return .{
            .normal = normal,
            .distance = normal.dot(p1),
        };
    }

    pub fn distanceToPoint(self: Planef, point: Pointf) f32 {
        return point.dot(self.normal) - self.distance;
    }

    pub fn pointOn(self: Planef, point: Pointf, epsilon: f32) bool {
        return point.dot(self.normal) - self.distance < epsilon;
    }

    pub fn closestPoint(self: Planef, point: Pointf) Pointf {
        return point.sub(Vector3f.splat(self.distanceToPoint(point)) * self.normal);
    }

    pub fn intersectionPoint(p1: Planef, p2: Planef, p3: Planef) ?Pointf {
        const m1: Vector3f = .{ .x = p1.normal.x, .y = p2.normal.x, .z = p3.normal.x };
        const m2: Vector3f = .{ .x = p1.normal.y, .y = p2.normal.y, .z = p3.normal.y };
        const m3: Vector3f = .{ .x = p1.normal.z, .y = p2.normal.z, .z = p3.normal.z };
        const d: Vector3f = .{ .x = p1.distance, .y = p2.distance, .z = p3.distance };

        const u = m2.cross(m3);
        const v = m1.cross(d);

        const denom = m1.dot(u);

        if (@abs(denom) < std.math.floatEps(f32)) {
            return null;
        }

        return .{
            .x = d.dot(u) / denom,
            .y = m3.dot(v) / denom,
            .z = -m2.dot(v) / denom,
        };
    }

    pub fn intersectsSphere(self: Planef, sphere: Spheref) bool {
        return sphere.intersectsPlane(self);
    }

    pub fn intersectsAabb(self: Planef, aabb: AABBf) bool {
        return aabb.intersectsPlane(self);
    }

    pub fn intersectsPlane(self: Planef, other: Planef, epsilon: f32) bool {
        return self.normal.cross(other.normal).lengthSquared() > epsilon;
    }
};

pub const LineSegmentf = extern struct {
    start: Pointf,
    end: Pointf,

    pub fn toVector(self: LineSegmentf) Vector3f {
        return self.end.sub(self.start);
    }

    pub fn length(self: LineSegmentf) f32 {
        return self.toVector().length();
    }

    pub fn lengthSquared(self: LineSegmentf) f32 {
        return self.toVector().lengthSquared();
    }

    pub fn pointOn(self: LineSegmentf, point: Pointf, epsilon: f32) bool {
        const m = (self.end.y - self.start.y) / (self.end.x - self.start.x);
        const b = self.start.y - m * self.start.x;

        return @abs(point.y - (m * point.x + b)) < epsilon;
    }

    pub fn closestPoint(self: LineSegmentf, point: Pointf) struct { Pointf, f32 } {
        const ab = self.toVector();

        const a = self.start;

        const t = std.math.clamp(point.sub(a).dot(ab) / ab.dot(ab), 0, 1);

        return .{ ab.mul(.splat(t)).add(a), t };
    }

    // Checks if the line segment intersects *the edge* of the sphere, it does not check containment
    pub fn intersectsSphere(self: LineSegmentf, sphere: Spheref) ?Pointf {
        const ray: Rayf = .from(self.start, self.end.sub(self.start));

        const t = ray.castToSphereTime(sphere) orelse return null;

        if (t > 0 and t * t < self.lengthSquared()) {
            return ray.tToPoint(t);
        }
    }

    /// Checks if the line segment intersects *the edge* of the AABB, it does not check containment
    pub fn intersectsAabb(self: LineSegmentf, aabb: AABBf) ?Pointf {
        const ray: Rayf = .from(self.start, self.end.sub(self.start));

        const t = ray.castToAabbTime(aabb) orelse return null;

        if (t > 0 and t * t < self.lengthSquared()) {
            return ray.tToPoint(t);
        }
    }

    /// Checks if the line segment intersects the plane
    pub fn intersectsPlane(self: LineSegmentf, plane: Planef) ?Pointf {
        const ray: Rayf = .from(self.start, self.end.sub(self.start));

        const t = ray.castToPlaneTime(plane) orelse return null;

        if (t > 0 and t * t < self.lengthSquared()) {
            return ray.tToPoint(t);
        }
    }
};

pub const Rayf = extern struct {
    position: Pointf,
    normal: Vector3f,

    pub fn from(position: Pointf, direction: Vector3f) Rayf {
        return .{ .position = position, .direction = direction.normalize() };
    }

    pub fn pointOn(self: Rayf, point: Pointf, epsilon: f32) bool {
        return @abs(1 - self.position.sub(point).normalize().dot(self.normal)) < epsilon;
    }

    pub fn closestPoint(self: Rayf, point: Pointf) Pointf {
        const ab: LineSegmentf = .{ .start = self.position, .end = self.position.add(self.normal) };

        const a = self.position;

        const t = @max(point.sub(a).dot(ab) / ab.dot(ab), 0);

        return self.normal.mul(.splat(t)).add(a);
    }

    pub fn tToPoint(self: Rayf, t: f32) Pointf {
        return @bitCast(self.position.toSimd() + (self.normal.toSimd() * @as(SimdVector3f, @splat(t))));
    }

    pub fn castToSphereTime(self: Rayf, sphere: Spheref) ?f32 {
        const p0 = self.position;
        const d = self.normal;
        const pc = sphere.position;
        const r = sphere.radius;

        const e = pc.sub(p0);
        const esq = e.lengthSquared();
        const a = e.dot(d);
        const b = @sqrt(esq - (a * a));
        const f = @sqrt((r * r) - (b * b));

        if ((r * r) - esq + (a * a) < 0) {
            // no collision
            return null;
        } else if (esq < (r * r)) {
            // ray is inside
            return a + f;
        }
        // normal intersection
        return a - f;
    }

    pub fn castToSphere(self: Rayf, sphere: Spheref) ?Pointf {
        return self.tToPoint(self.castToSphereTime(sphere) orelse return null);
    }

    pub fn castToAabbTime(self: Rayf, aabb: AABBf) ?f32 {
        const t135 = (aabb.min.toSimd() - self.position.toSimd()) / self.normal.toSimd();
        const t246 = (aabb.max.toSimd() - self.position.toSimd()) / self.normal.toSimd();

        const t_min = @reduce(.Max, @min(t135, t246));
        const t_max = @reduce(.Min, @max(t135, t246));

        // ray is intersecting, but its behind us
        if (t_max < 0) {
            return null;
        }

        // doesn't intersect
        if (t_min > t_max) {
            return null;
        }

        if (t_min < 0) {
            return t_max;
        }

        return t_min;
    }

    pub fn castToAabb(self: Rayf, aabb: AABBf) ?Pointf {
        return self.tToPoint(self.castToAabbTime(aabb) orelse return null);
    }

    pub fn castToPlaneTime(self: Rayf, plane: Planef) ?f32 {
        const nd = self.normal.dot(plane.normal);
        const pn = self.position.dot(plane.normal);

        if (nd >= 0) {
            return null;
        }

        const t = plane.distance - pn / nd;

        if (t > 0) {
            return t;
        }

        return null;
    }

    pub fn castToPlane(self: Rayf, plane: Planef) ?Pointf {
        return self.tToPoint(self.castToPlaneTime(plane) orelse return null);
    }
};

pub const Matrix4x4f = extern struct {
    m: [16]f32,

    pub const identity: Matrix4x4f = .{ .m = .{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    } };

    pub fn from(xr: c.XrMatrix4x4f) Matrix4x4f {
        return @bitCast(xr);
    }

    pub fn to(self: Matrix4x4f) c.XrMatrix4x4f {
        return @bitCast(self);
    }

    pub fn mult(self: *const Matrix4x4f, other: *const Matrix4x4f) Matrix4x4f {
        var curr: Matrix4x4f = undefined;
        c.XrMatrix4x4f_Multiply(@ptrCast(&curr), @ptrCast(self), @ptrCast(other));
        return curr;
    }

    pub fn transformVector3(self: *const Matrix4x4f, vec: Vector3f) Vector3f {
        var ret: Vector3f = undefined;
        c.XrMatrix4x4f_TransformVector3f(@ptrCast(&ret), @ptrCast(self), @ptrCast(&vec));
        return ret;
    }

    pub fn createRotation(x: f32, y: f32, z: f32) Matrix4x4f {
        var ret: Matrix4x4f = undefined;
        c.XrMatrix4x4f_CreateRotationRadians(@ptrCast(&ret), x, y, z);
        return ret;
    }

    pub fn createTranslation(translation: Vector3f) Matrix4x4f {
        var ret: Matrix4x4f = undefined;
        c.XrMatrix4x4f_CreateTranslation(@ptrCast(&ret), translation.x, translation.y, translation.z);
        return ret;
    }

    pub fn createScale(scale: Vector3f) Matrix4x4f {
        var ret: Matrix4x4f = undefined;
        c.XrMatrix4x4f_CreateScale(@ptrCast(&ret), scale.x, scale.y, scale.z);
        return ret;
    }

    pub fn createTranslationRotationScale(translation: Vector3f, rotation: Quaternionf, scale: Vector3f) Matrix4x4f {
        var ret: Matrix4x4f = undefined;
        c.XrMatrix4x4f_CreateTranslationRotationScale(@ptrCast(&ret), @ptrCast(&translation), @ptrCast(&rotation), @ptrCast(&scale));
        return ret;
    }

    pub fn createProjectionFov(fov: c.XrFovf, near_z: f32, far_z: f32) Matrix4x4f {
        var ret: Matrix4x4f = undefined;
        c.XrMatrix4x4f_CreateProjectionFov(@ptrCast(&ret), c.GRAPHICS_D3D, fov, near_z, far_z);
        return ret;
    }

    pub fn createFromPose(pose: c.XrPosef) Matrix4x4f {
        return createTranslationRotationScale(@bitCast(pose.position), @bitCast(pose.orientation), .{ .x = 1, .y = 1, .z = 1 });
    }

    pub fn invert(self: Matrix4x4f) Matrix4x4f {
        var ret: Matrix4x4f = undefined;
        c.XrMatrix4x4f_Invert(@ptrCast(&ret), @ptrCast(&self));
        return ret;
    }

    pub fn invertRigidBody(self: Matrix4x4f) Matrix4x4f {
        const m12 = -(self.m[0] * self.m[12] + self.m[1] * self.m[13] + self.m[2] * self.m[14]);
        const m13 = -(self.m[4] * self.m[12] + self.m[5] * self.m[13] + self.m[6] * self.m[14]);
        const m14 = -(self.m[8] * self.m[12] + self.m[9] * self.m[13] + self.m[10] * self.m[14]);

        return .{
            .m = .{
                self.m[0], self.m[4], self.m[8],  0,
                self.m[1], self.m[5], self.m[9],  0,
                self.m[2], self.m[6], self.m[10], 0,
                m12,       m13,       m14,        1,
            },
        };
    }

    pub fn getRotation(self: Matrix4x4f) Quaternionf {
        var ret: c.XrQuaternionf = undefined;
        c.XrMatrix4x4f_GetRotation(&ret, @ptrCast(&self));
        return @bitCast(ret);
    }

    pub fn getTranslation(self: Matrix4x4f) Vector3f {
        var ret: c.XrVector3f = undefined;
        c.XrMatrix4x4f_GetTranslation(&ret, @ptrCast(&self));
        return @bitCast(ret);
    }

    pub fn getPose(self: Matrix4x4f) c.XrPosef {
        return .{
            .position = self.getTranslation().to(),
            .orientation = self.getRotation().to(),
        };
    }
};
